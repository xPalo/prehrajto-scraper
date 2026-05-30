class OtpRegistrationsController < ApplicationController
  # Step 1: user submitted an email from the OTP tab on the sign-up screen.
  # We always respond the same way (redirect to the verify step) regardless of
  # whether the email already has an account, to avoid leaking which emails
  # exist. If it does exist we quietly send a normal *login* code, so verifying
  # just signs that user in; otherwise we send a *registration* code and keep
  # the pending registration in the session until it's verified.
  def create
    email = params[:email].to_s.strip.downcase

    if (user = User.find_by(email: email))
      code = user.generate_otp!
      OtpMailer.login_code(user.id, code).deliver_later
    else
      code = User.generate_otp_code
      session[:reg_otp_digest]  = User.otp_digest(code)
      session[:reg_otp_sent_at] = Time.current.iso8601
      OtpMailer.registration_code(email, code).deliver_later
    end

    session[:reg_otp_email] = email
    # _url (not _path) so the redirect keeps the public :46580 port behind the
    # reverse proxy — see default_url_options in ApplicationController.
    redirect_to user_otp_register_verify_url, notice: t(:'devise.otp_register_sent')
  end

  # Step 2 (GET): render the code-entry form.
  def verify
    return redirect_to new_user_registration_url if session[:reg_otp_email].blank?

    @email = session[:reg_otp_email]
  end

  # Step 2 (POST): verify the submitted code, then either create the account
  # (new email) or sign the existing user in (email already registered).
  def confirm
    email = session[:reg_otp_email]
    user  = User.find_by(email: email)

    if user
      ok = user.verify_otp(params[:otp_code])
      user.clear_otp! if ok
    else
      sent_at = session[:reg_otp_sent_at] && Time.zone.parse(session[:reg_otp_sent_at])
      ok = User.otp_valid?(session[:reg_otp_digest], sent_at, params[:otp_code])
      user = create_otp_user(email) if ok
    end

    if ok && user
      clear_reg_otp_session
      # Set remember_me before sign_in so Devise's rememberable hook drops the
      # remember cookie, matching the password form (which always remembers).
      user.remember_me = true
      sign_in(user)
      redirect_to after_sign_in_path_for(user), notice: t(:'devise.otp_registered')
    else
      flash.now[:alert] = t(:'devise.otp_invalid')
      @email = email
      render :verify, status: :unprocessable_entity
    end
  end

  private

  # OTP-registered users get an unguessable random password (Devise's
  # :validatable requires one). They sign in via OTP going forward, or set a
  # real password later through the "forgot password" flow.
  def create_otp_user(email)
    pw = Devise.friendly_token(32)
    User.create!(email: email, password: pw, password_confirmation: pw)
  end

  def clear_reg_otp_session
    session.delete(:reg_otp_email)
    session.delete(:reg_otp_digest)
    session.delete(:reg_otp_sent_at)
  end
end

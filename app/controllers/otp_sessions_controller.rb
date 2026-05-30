class OtpSessionsController < ApplicationController
  # Step 1: user submitted an email from the OTP tab on the login screen.
  # We always respond the same way (redirect to the verify step) regardless of
  # whether the email matches an account, to avoid leaking which emails exist.
  def create
    email = params[:email].to_s.strip.downcase

    if (user = User.find_by(email: email))
      code = user.generate_otp!
      OtpMailer.login_code(user.id, code).deliver_later
    end

    session[:otp_email] = email
    # _url (not _path) so the redirect keeps the public :46580 port behind the
    # reverse proxy — see default_url_options in ApplicationController.
    redirect_to user_otp_verify_url, notice: t(:'devise.otp_sent')
  end

  # Step 2 (GET): render the code-entry form.
  def verify
    return redirect_to new_user_session_url if session[:otp_email].blank?

    @email = session[:otp_email]
  end

  # Step 2 (POST): verify the submitted code and sign the user in.
  def confirm
    user = User.find_by(email: session[:otp_email])

    if user&.verify_otp(params[:otp_code])
      user.clear_otp!
      session.delete(:otp_email)
      # Set remember_me before sign_in so Devise's rememberable hook drops the
      # remember cookie, matching the password form (which always remembers).
      user.remember_me = true
      sign_in(user)
      redirect_to after_sign_in_path_for(user), notice: t(:'devise.otp_signed_in')
    else
      flash.now[:alert] = t(:'devise.otp_invalid')
      @email = session[:otp_email]
      render :verify, status: :unprocessable_entity
    end
  end
end

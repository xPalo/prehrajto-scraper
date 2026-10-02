# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"

# Chart deps are vendored as self-contained esbuild bundles. Loading them from
# ga.jspm.io meant ~260 module requests (date-fns alone is 258), and any single
# failed one broke chart_controller with "Failed to fetch dynamically imported module".
# To rebuild, run in a scratch dir OUTSIDE the repo (APP=/path/to/prehrajto-scraper);
# with these exact versions the output matches the committed files byte for byte:
#   npm i chart.js@4.4.4 @kurkle/color@0.3.4 chartjs-adapter-date-fns@3.0.0 date-fns@3.6.0 esbuild@0.24.0
#   echo 'export * from "chart.js"' > entry.js
#   npx esbuild entry.js --bundle --format=esm --minify --legal-comments=inline \
#     --banner:js='/* chart.js@4.4.4 + @kurkle/color@0.3.4, bundled with esbuild (see config/importmap.rb) */' \
#     --outfile=$APP/vendor/javascript/chart.js
#   npx esbuild node_modules/chartjs-adapter-date-fns/dist/chartjs-adapter-date-fns.esm.js \
#     --bundle --format=esm --minify --legal-comments=inline --external:chart.js \
#     --banner:js='/* chartjs-adapter-date-fns@3.0.0 + date-fns@3.6.0 (tree-shaken), bundled with esbuild (see config/importmap.rb) */' \
#     --outfile=$APP/vendor/javascript/chartjs-adapter-date-fns.js
# date-fns and @kurkle/color live inside the bundles, so `bin/importmap audit` no longer sees them.
pin "chart.js", to: "chart.js" # @4.4.4
pin "chartjs-adapter-date-fns" # @3.0.0
pin "tom-select", to: "https://ga.jspm.io/npm:tom-select@2.4.3/dist/esm/tom-select.complete.js"
pin "@orchidjs/sifter", to: "https://ga.jspm.io/npm:@orchidjs/sifter@1.1.0/dist/esm/sifter.js"
pin "@orchidjs/unicode-variants", to: "https://ga.jspm.io/npm:@orchidjs/unicode-variants@1.1.2/dist/esm/index.js"

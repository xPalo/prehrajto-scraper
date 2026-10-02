# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"

# Chart deps are vendored as self-contained esbuild bundles. Loading them from
# ga.jspm.io meant ~260 module requests (date-fns alone is 258), and any single
# failed one broke chart_controller with "Failed to fetch dynamically imported module".
# To rebuild: npm i chart.js@4.4.4 chartjs-adapter-date-fns@3.0.0 date-fns@3.6.0 esbuild, then
#   echo 'export * from "chart.js"' > entry.js
#   npx esbuild entry.js --bundle --format=esm --minify --outfile=vendor/javascript/chart.js
#   npx esbuild node_modules/chartjs-adapter-date-fns/dist/chartjs-adapter-date-fns.esm.js \
#     --bundle --format=esm --minify --external:chart.js --outfile=vendor/javascript/chartjs-adapter-date-fns.js
pin "chart.js", to: "chart.js" # @4.4.4
pin "chartjs-adapter-date-fns" # @3.0.0
pin "tom-select", to: "https://ga.jspm.io/npm:tom-select@2.4.3/dist/esm/tom-select.complete.js"
pin "@orchidjs/sifter", to: "https://ga.jspm.io/npm:@orchidjs/sifter@1.1.0/dist/esm/sifter.js"
pin "@orchidjs/unicode-variants", to: "https://ga.jspm.io/npm:@orchidjs/unicode-variants@1.1.2/dist/esm/index.js"

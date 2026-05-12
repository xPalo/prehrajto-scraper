# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"

pin "chart.js", to: "https://ga.jspm.io/npm:chart.js@4.4.4/dist/chart.js"
pin "@kurkle/color", to: "https://ga.jspm.io/npm:@kurkle/color@0.3.2/dist/color.esm.js"
pin "chartjs-adapter-date-fns", to: "https://ga.jspm.io/npm:chartjs-adapter-date-fns@3.0.0/dist/chartjs-adapter-date-fns.esm.js"
pin "date-fns", to: "https://ga.jspm.io/npm:date-fns@3.6.0/index.js"
pin "tom-select", to: "https://ga.jspm.io/npm:tom-select@2.4.3/dist/esm/tom-select.complete.js"
pin "@orchidjs/sifter", to: "https://ga.jspm.io/npm:@orchidjs/sifter@1.1.0/dist/esm/sifter.js"
pin "@orchidjs/unicode-variants", to: "https://ga.jspm.io/npm:@orchidjs/unicode-variants@1.1.2/dist/esm/index.js"

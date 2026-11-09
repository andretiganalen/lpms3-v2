# Dipakai setelah kode plugin tersedia (sprint S1). Sebelum itu jalankan image resmi (Buku Teknis F2S) tanpa build ini.
ARG OP_TAG=17.9.6
FROM openproject/openproject:${OP_TAG}
COPY plugin/openproject-lpms3 /app/custom-plugins/openproject-lpms3
COPY deploy/Gemfile.plugins /app/Gemfile.plugins
RUN bundle config unset deployment && bundle install && bundle config set deployment 'true'
RUN ./docker/prod/setup/postinstall.sh

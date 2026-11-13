# Image OpenProject + plugin LPMS3 (tema UIx, Organisasi & Fungsi, sidebar). Dibangun dari konteks root repo:
#   docker build -f deploy/Dockerfile -t lpms3/openproject:local .
# OP_IMAGE harus sama dengan image yang dipakai deploy/docker-compose.stock.yml sebelum plugin.
ARG OP_IMAGE=openproject/openproject:17-slim
FROM ${OP_IMAGE}
COPY --chown=app:app plugin/openproject-lpms3 /app/custom-plugins/openproject-lpms3
COPY --chown=app:app deploy/Gemfile.plugins /app/Gemfile.plugins
COPY --chown=app:app deploy/patch_gemfile_lock.rb /tmp/patch_gemfile_lock.rb
# Plugin tidak punya dependensi gem baru dan tidak punya aset frontend (CSS dilayani plugin sendiri),
# jadi cukup mendaftarkannya ke Gemfile.lock; tidak perlu `bundle install` maupun precompile.
RUN ruby /tmp/patch_gemfile_lock.rb 0.1.0 /app/custom-plugins/openproject-lpms3 \
 && rm /tmp/patch_gemfile_lock.rb \
 && bundle exec ruby -e 'abort("plugin tidak termuat") unless Gem.loaded_specs["openproject-lpms3"]'

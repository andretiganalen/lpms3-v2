# Image OpenProject + plugin LPMS3 (tema UIx, Organisasi & Fungsi, sidebar). Dibangun dari konteks root repo:
#   docker build -f deploy/Dockerfile -t lpms3/openproject:local .
# OP_IMAGE harus sama dengan image yang dipakai deploy/docker-compose.stock.yml sebelum plugin.
# Dipin ke digest OP 17.9.7 (diuji 2026-11-14). Ganti hanya lewat prosedur upgrade.
ARG OP_IMAGE=openproject/openproject:17-slim@sha256:4e978557b4009dfdcdab6f18acd1aa9348a2c41ce5cd50c3d535e4c093a5c505
FROM ${OP_IMAGE}
COPY --chown=app:app plugin/openproject-lpms3 /app/custom-plugins/openproject-lpms3
COPY --chown=app:app deploy/Gemfile.plugins /app/Gemfile.plugins
COPY --chown=app:app deploy/patch_gemfile_lock.rb /tmp/patch_gemfile_lock.rb
# Plugin tidak punya dependensi gem baru dan tidak punya aset frontend (CSS dilayani plugin sendiri),
# jadi cukup mendaftarkannya ke Gemfile.lock; tidak perlu `bundle install` maupun precompile.
RUN ruby /tmp/patch_gemfile_lock.rb 0.1.0 /app/custom-plugins/openproject-lpms3 \
 && rm /tmp/patch_gemfile_lock.rb \
 && bundle exec ruby -e 'abort("plugin tidak termuat") unless Gem.loaded_specs["openproject-lpms3"]'
# MOD-05: netralisasi tautan keluar ke openproject.*/github opf/chargebee/youtube di static_links.yml -> "/" (tanpa kontak vendor).
RUN sed -i -E 's#(href:[[:space:]]*)https?://([a-z0-9.-]*\.)?(openproject\.org|openproject\.com|openproject-docs\.s3[a-z0-9.-]*\.amazonaws\.com|chargebee\.com|youtube\.com)[^[:space:]]*#\1"/"#; s#(href:[[:space:]]*)https://github\.com/opf/[^[:space:]]*#\1"/"#' /app/config/static_links.yml \
 && ! grep -E 'href:[[:space:]]*https?://([a-z0-9.-]*\.)?(openproject|chargebee)' /app/config/static_links.yml \
 && ruby -ryaml -e 'YAML.load_file("/app/config/static_links.yml")'
# MOD-04: security badge (memuat gambar dari releases.openproject.com dan mengirim uuid/versi) tidak pernah ditampilkan.
RUN sed -i 's#OpenProject::Configuration.security_badge_displayed? && Setting.security_badge_displayed?#false#' /app/app/helpers/security_badge_helper.rb \
 && grep -q '^    false$' /app/app/helpers/security_badge_helper.rb
# MOD-06: matikan Gravatar dan bersihkan domain eksternal di CSP.
COPY --chown=app:app deploy/patch_mod06.rb /tmp/patch_mod06.rb
RUN ruby /tmp/patch_mod06.rb && rm /tmp/patch_mod06.rb && ruby -c /app/config/initializers/content_security_policy.rb
# MOD-07: default app_title dan organization_name = identitas portal internal.
COPY --chown=app:app deploy/patch_mod07.rb /tmp/patch_mod07.rb
RUN ruby /tmp/patch_mod07.rb && rm /tmp/patch_mod07.rb && ruby -c /app/config/constants/settings/definition.rb
# MOD-08: logo & favicon OpenProject diganti logo Len 2023 (aset di deploy/brand, ditanam ke image).
COPY --chown=app:app deploy/brand /tmp/brand
COPY --chown=app:app deploy/patch_mod08.sh /tmp/patch_mod08.sh
RUN sh /tmp/patch_mod08.sh && rm -rf /tmp/brand /tmp/patch_mod08.sh
# MOD-09: hapus Edisi Enterprise dan Link Eksternal (menu, route, dan setting capture link).
COPY --chown=app:app deploy/patch_mod09.rb /tmp/patch_mod09.rb
RUN ruby /tmp/patch_mod09.rb && rm /tmp/patch_mod09.rb && ruby -c /app/config/initializers/menus.rb && ruby -c /app/config/routes.rb && ruby -c /app/config/constants/settings/definition.rb
# 1.49: teks UI frontend (bahasa id & en) tanpa "OpenProject"; tautan situs openproject.org/.com -> "/" (identifier JS window.OpenProject tidak disentuh).
RUN cd /app/public/assets/frontend \
 && sed -i -E 's#https?://([a-z0-9-]+\.)*openproject\.(org|com)[^"'"'"'`) <>\\]*#/#g' $(grep -rlE 'openproject\.(org|com)' . || true) \
 && sed -i 's/OpenProject/LPMS/g' src/locales/id-*.js src/locales/en-*.js src/locales/en.js 2>/dev/null || true \
 && ! grep -l "OpenProject" src/locales/id-*.js

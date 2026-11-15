# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# See COPYRIGHT and LICENSE files for more details.
#++

# LPMS3: pengaturan tampilan in-house (logo, favicon/thumbnail, warna). Pengganti halaman Design OpenProject
# yang dikunci fitur Enterprise; TIDAK memakai CustomStyle/EnterpriseToken. Nilai disimpan di tabel `settings`
# (logo/favicon sebagai data URI base64, ikut backup database).
module OpenProject::Lpms3
  module Branding
    MAX_BYTES = 300 * 1024
    COLOR_KEYS = %i[color_primary color_header_bg color_header_text color_menu_selected].freeze
    IMAGE_KEYS = %i[logo favicon].freeze
    KEYS = (IMAGE_KEYS + COLOR_KEYS).freeze
    HEX = /\A#[0-9a-fA-F]{6}\z/
    # Nilai bawaan UIx (token): pemilih warna diisi ini; nilai yang sama dengan bawaan tidak disimpan sebagai override.
    DEFAULTS = { color_primary: "#ae2524", color_header_bg: "#ffffff", color_header_text: "#364153", color_menu_selected: "#f3f4f6" }.freeze

    module_function

    def setting(key) = Setting.public_send(:"lpms3_#{key}").to_s

    def set(key, value) = Setting.public_send(:"lpms3_#{key}=", value.to_s)

    def valid_color?(value) = HEX.match?(value.to_s)

    # Deteksi tipe dari isi berkas (bukan dari klaim browser). Mengembalikan mime atau nil.
    def sniff(bytes)
      b = bytes.b
      return "image/png" if b.start_with?("\x89PNG\r\n\x1A\n".b)
      return "image/jpeg" if b.start_with?("\xFF\xD8\xFF".b)
      return "image/x-icon" if b.start_with?("\x00\x00\x01\x00".b)
      return "image/webp" if b.start_with?("RIFF".b) && b[8, 4] == "WEBP".b

      text = b[0, 2048].to_s.force_encoding("UTF-8").scrub
      "image/svg+xml" if text.include?("<svg") && !text.match?(/<script|onload\s*=|javascript:/i)
    end

    # Hasil: [data_uri, nil] atau [nil, pesan_galat]
    def data_uri_from(upload)
      bytes = upload.read
      return [nil, "Berkas kosong"] if bytes.blank?
      return [nil, "Ukuran maksimal #{MAX_BYTES / 1024} KB"] if bytes.bytesize > MAX_BYTES

      mime = sniff(bytes)
      return [nil, "Format harus PNG, JPEG, WEBP, ICO, atau SVG (tanpa skrip)"] unless mime

      ["data:#{mime};base64,#{[bytes].pack("m0")}", nil]
    end

    def darken(hex, factor = 0.82)
      "#" + hex.delete("#").scan(/../).map { |c| (c.hex * factor).round.to_s(16).rjust(2, "0") }.join
    end

    def rgba(hex, alpha)
      r, g, b = hex.delete("#").scan(/../).map(&:hex)
      "rgba(#{r}, #{g}, #{b}, #{alpha})"
    end

    # CSS yang disuntikkan ke <head>; kosong bila belum ada pengaturan.
    def css
      vars = []
      if valid_color?(p = setting(:color_primary))
        vars += ["--uix-primary:#{p}", "--uix-primary-strong:#{darken(p)}", "--uix-primary-soft:#{rgba(p, 0.10)}"]
      end
      if valid_color?(h = setting(:color_header_bg))
        vars << "--header-bg-color:#{h}"
      end
      if valid_color?(t = setting(:color_header_text))
        vars += ["--header-item-font-color:#{t}", "--header-item-font-hover-color:#{t}"]
      end
      if valid_color?(m = setting(:color_menu_selected))
        vars << "--main-menu-bg-selected-background:#{m}"
      end
      out = +""
      out << ":root:root{#{vars.join(';')}}" if vars.any?
      logo = setting(:logo)
      out << ".op-logo--link,.op-logo--icon{background-image:url(\"#{logo}\")!important;background-repeat:no-repeat;background-position:left center;background-size:contain}" if logo.start_with?("data:image/")
      out
    end

    def favicon = setting(:favicon).start_with?("data:image/") ? setting(:favicon) : nil
  end
end

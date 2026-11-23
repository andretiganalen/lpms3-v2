# frozen_string_literal: true

module Lpms3
  # Penerima pemicu proyek dari LenO (docs/plan/RANCANGAN-PEMICU-LENO.md §4).
  # Bukan ApplicationController: tanpa sesi, tanpa login pengguna, tanpa CSRF. Satu-satunya autentikasi adalah kunci
  # bersama di header X-Lpms3-Key, dibandingkan constant-time dengan LPMS3_LENO_KEYS (boleh dua nilai dipisah koma
  # untuk rotasi). Kunci kosong = semua permintaan ditolak 401.
  class PemicuLenoController < ::ActionController::API
    MAX_BODY = 16.kilobytes
    MIN_KEY_LENGTH = 32
    HEADER = "X-Lpms3-Key"

    # Batas laju dijalankan lebih dulu dari autentikasi agar tebakan kunci juga dibatasi.
    rate_limit to: 60, within: 1.minute, by: -> { request.remote_ip }, store: Rails.cache,
               with: -> { reply(429, { galat: "terlalu_banyak_permintaan" }) }
    before_action :authenticate!

    def create
      return reply(413, { galat: "body_terlalu_besar" }) if request.content_length.to_i > MAX_BODY

      raw = request.raw_post.to_s
      return reply(413, { galat: "body_terlalu_besar" }) if raw.bytesize > MAX_BODY

      data = begin
        JSON.parse(raw)
      rescue JSON::ParserError
        nil
      end
      return reply(400, { galat: "json_tidak_sah" }) unless data.is_a?(Hash)

      input, errors = parse(data)
      return reply(400, { galat: "isian_tidak_sah", rincian: errors }) if errors.any?

      trigger, outcome = ::Lpms3::ProjectTrigger.receive!(**input, alamat: request.remote_ip)
      status = { baru: 202, ulang: 202, final: 200, konflik: 409 }.fetch(outcome)
      body = trigger.api_json
      body = { galat: "lpms2_proyek_id_berbeda", kode_proyek: trigger.kode_proyek } if outcome == :konflik
      reply(status, body, kode: trigger.kode_proyek, hasil: outcome)
    rescue ActiveRecord::RecordInvalid => e
      reply(400, { galat: "isian_tidak_sah", rincian: e.record.errors.full_messages })
    end

    def show
      kode = ::Lpms3::ProjectTrigger.normalize_kode(params[:kode_proyek])
      trigger = ::Lpms3::ProjectTrigger.find_by(kode_proyek: kode)
      return reply(404, { galat: "tidak_ditemukan" }, kode:) unless trigger

      reply(200, trigger.api_json, kode:)
    end

    private

    def authenticate!
      keys = ENV.fetch("LPMS3_LENO_KEYS", "").split(",").map(&:strip).select { |k| k.length >= MIN_KEY_LENGTH }
      given = request.headers[HEADER].to_s
      return if given.present? && keys.any? { |k| ActiveSupport::SecurityUtils.secure_compare(k, given) }

      reply(401, { galat: "kunci_tidak_sah" })
    end

    # Validasi kontrak §4.1. Mengembalikan [argumen untuk receive!, daftar galat].
    def parse(data)
      errors = []
      kode = ::Lpms3::ProjectTrigger.normalize_kode(data["kode_proyek"])
      errors << "kode_proyek wajib, huruf/angka/._/- maks. 40 karakter" unless kode.match?(::Lpms3::ProjectTrigger::KODE_RE)
      id_kiriman = data["id_kiriman"].to_s.strip
      errors << "id_kiriman wajib, maks. 100 karakter" if id_kiriman.empty? || id_kiriman.length > 100

      lpms2_id = data["lpms2_proyek_id"]
      lpms2_id = Integer(lpms2_id.to_s, 10, exception: false) unless lpms2_id.nil?
      errors << "lpms2_proyek_id harus bilangan bulat positif" if data.key?("lpms2_proyek_id") && !data["lpms2_proyek_id"].nil? && !lpms2_id&.positive?

      nota = {}
      if data["nota"].is_a?(Hash)
        nomor = data["nota"]["nomor"].to_s.strip
        errors << "nota.nomor maks. 100 karakter" if nomor.length > 100
        nota["nomor"] = nomor if nomor.present?
        if data["nota"]["tanggal"].present?
          tanggal = Date.iso8601(data["nota"]["tanggal"].to_s) rescue nil
          if tanggal
            nota["tanggal"] = tanggal.iso8601
          else
            errors << "nota.tanggal harus YYYY-MM-DD"
          end
        end
      elsif !data["nota"].nil?
        errors << "nota harus objek"
      end

      dikirim = nil
      if data["dikirim_pada"].present?
        dikirim = Time.iso8601(data["dikirim_pada"].to_s) rescue nil
        errors << "dikirim_pada harus ISO 8601" unless dikirim
      end

      [{ kode_proyek: kode, id_kiriman:, lpms2_proyek_id: lpms2_id, nota:, dikirim_pada: dikirim }, errors]
    end

    # Log hanya metadata: tanpa kunci dan tanpa body mentah.
    def reply(status, body, kode: nil, hasil: nil)
      Rails.logger.info("[LPMS3] pemicu LenO #{action_name} http=#{status} kode=#{kode || '-'} hasil=#{hasil || '-'} ip=#{request.remote_ip}")
      render json: body, status:
    end
  end
end

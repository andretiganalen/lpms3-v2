require "digest"

module OpenProject::Lpms3
  # Daftar aset yang boleh dilayani (daftar putih, tanpa path bebas) + digest untuk cache-busting.
  module Assets
    module_function

    TYPES = { ".css" => "text/css", ".woff2" => "font/woff2", ".txt" => "text/plain" }.freeze

    def files
      @files ||= Dir[File.join(ASSET_ROOT, "{uix,fonts}", "*")].to_h do |f|
        [f.delete_prefix("#{ASSET_ROOT}/"), f]
      end.select { |_, f| TYPES.key?(File.extname(f)) }.freeze
    end

    def type_for(path)
      TYPES.fetch(File.extname(path))
    end

    def digest
      Digest::MD5.hexdigest(files.sort.map { |k, f| "#{k}#{File.size(f)}#{File.mtime(f).to_i}" }.join)[0, 10]
    end
  end
end

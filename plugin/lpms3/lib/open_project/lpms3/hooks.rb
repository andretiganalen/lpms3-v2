module OpenProject::Lpms3
  # Menyuntikkan tema UIx ke <head> semua halaman (Aturan UIx 9.1).
  class Hooks < OpenProject::Hook::ViewListener
    render_on :view_layouts_base_html_head, partial: "hooks/lpms3/head"
  end
end

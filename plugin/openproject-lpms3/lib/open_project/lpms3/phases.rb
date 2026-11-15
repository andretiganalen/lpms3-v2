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

# LPMS3: lima fase BOP-001 (Master Plan §5): Inisiasi, Perencanaan, Eksekusi, Pengawasan & Pengendalian, Penutupan.
# Pengelompokan langkah memakai awalan subjek template "[T1-..]" (Inisiasi), "[T2-..]", "[T3-..]", "[T5-..]", "[T6-..]";
# gerbang G1-G4 adalah milestone "G1 — ...". G3 (Serah terima) menutup Eksekusi sekaligus Pengawasan & Pengendalian.
module OpenProject::Lpms3
  module Phases
    Phase = Struct.new(:key, :prefix, :icon, :gates, :types, keyword_init: true)

    ALL = [
      Phase.new(key: "inisiasi", prefix: "T1", icon: "rocket", gates: %w[G1], types: ["Dokumen Proyek"]),
      Phase.new(key: "perencanaan", prefix: "T2", icon: "calendar", gates: %w[G2], types: ["Dokumen Rencana", "Stakeholder"]),
      Phase.new(key: "eksekusi", prefix: "T3", icon: "play", gates: %w[G3],
                types: ["Deliverable", "Item Pengadaan", "Action Item"]),
      Phase.new(key: "pengawasan", prefix: "T5", icon: "eye", gates: %w[G3],
                types: ["Change Request", "Risiko", "Bahaya K3L", "Isu", "Inspeksi Mutu", "NCR", "Top Up Anggaran"]),
      Phase.new(key: "penutupan", prefix: "T6", icon: "check-circle", gates: %w[G4], types: ["Lesson Learned", "Dokumen Proyek"])
    ].freeze

    module_function

    def find(key) = ALL.find { |p| p.key == key.to_s }

    def index_of(phase) = ALL.index(phase)

    def menu_name(phase, section = nil) = [:lpms3_fase, phase.key, section].compact.join("_").to_sym

    # Kunci terjemahan: lpms3.phases.<key>.title
    def title_key(phase) = :"lpms3.phases.#{phase.key}.title"

    # Judul menu sidebar (lebih pendek agar tidak terpotong)
    def menu_title_key(phase) = :"lpms3.phases.#{phase.key}.menu_title"
  end
end

require 'caracal'

module Export

  # Exports an OTU to the MS Word .docx format
  # using [caracal](https://github.com/urvin-compliance/caracal) library to generate the docx
  module Docx

    # @return [Scope]
    #   Should return the full set of Otus that are to be sent.
    def self.otus(otu_id)
      o = ::Otu.find(otu_id)
      return ::Otu.none if o.taxon_name_id.nil?
      
      a = o.taxon_name.self_and_descendants
      ::Otu.joins(:taxon_name).where(taxon_name: a)
    end

    def self.build_doc(doc, otus)

        # page 1
        doc.h1 'OTU Export'
        doc.hr
        doc.p
        doc.h2 'Section 1'
        doc.p  'Raw dump'
        doc.p
        # doc.table otus, border_size: 4 do
        #   cell_style rows[0], background: 'cccccc', bold: true
        # end
      
        # page 2
        doc.page
        doc.h1 'Formatted stuffs'
        doc.hr
        doc.p
        doc.h2 'OTU List'
        doc.ul do
            otus.each do |otu|
                li "OTU: #{otu.inspect()}"
            end
        end
        # doc.p
        # doc.img 'https://www.example.com/logo.png', width: 500, height: 300

    end

    def self.export(otu_id)
      otus = otus(otu_id)

      # TODO: This will likely have to change, it is renamed on serving the file.
      export_file_path = "/tmp/_#{SecureRandom.hex(8)}_.docx"

      Caracal::Document.save export_file_path do |doc|
        build_doc(doc, otus)
      end

      export_file_path
    end

    def self.download(otu, request = nil)
      file_path = ::Export::Docx.export(otu.id)
      name = "docx_otu_id_#{otu.id}_#{DateTime.now}.docx"

      ::Download.create!(
        name: "docx download for #{otu.otu_name} on #{Time.now}.",
        description: 'A docx export of an OTU',
        filename: name,
        source_file_path: file_path,
        request: request,
        expires: 2.days.from_now
      )
    end

    # def self.download_async(otu, request = nil)
    #   download = ::Download.create!(
    #     name: "docx download for #{otu.otu_name} on #{Time.now}.",
    #     description: 'A docx export of an otu',
    #     filename: "otu_id_#{otu.id}_#{DateTime.now}.docx",
    #     request: request,
    #     expires: 2.days.from_now
    #   )

    #   TODO async downloading - copied from ColdpCreateDownloadJob
    #   DocxCreateDownloadJob.perform_later(otu, download)

    #   download
    # end

  end
end
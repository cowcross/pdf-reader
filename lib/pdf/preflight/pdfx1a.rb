# coding: utf-8

module PDF
  module Preflight
    class PDFX1A
      def check(input)
        if File.file?(input)
          check_filename(input)
        elsif input.is_a?(IO)
          check_io(input)
        else
          raise ArgumentError, "input must be a string with a filename or an IO object"
        end
      end

      private

      def check_filename(filename)
        File.open(filename, "rb") do |file|
          return check_io(file)
        end
      end

      def check_io(io)
        check_receivers(io) + check_hash(io)
      end

      # TODO: this is nasty, we parse the full file once for each receiver.
      #       PDF::Reader needs to be updated to support multiple receivers
      #
      def check_receivers(io)
        receivers.map { |rec|
          begin
            PDF::Reader.new.parse(io, rec)
            rec.message
          rescue PDF::Reader::UnsupportedFeatureError
            nil
          end
        }.compact
      end

      def check_hash(io)
        ohash = PDF::Reader::ObjectHash.new(io)

        hash_checks.map { |chk|
          chk.message(ohash)
        }.compact
      end

      def hash_checks
        [
          PDF::Preflight::Checks::CompressionAlgorithms.new(:CCITTFaxDecode, :DCTDecode, :FlateDecode, :RunLengthDecode),
          PDF::Preflight::Checks::DocumentId.new,
          PDF::Preflight::Checks::NoEncryption.new,
          PDF::Preflight::Checks::OnlyEmbeddedFonts.new,
          PDF::Preflight::Checks::NoFontSubsets.new
        ]
      end

      # TODO: MinPpi isn't part of the PDFX/1a spec, move it to another profile
      def receivers
        [
          PDF::Preflight::Receivers::BoxNesting.new,
          PDF::Preflight::Receivers::MaxVersion.new(1.4),
          PDF::Preflight::Receivers::MinPpi.new(298),
          PDF::Preflight::Receivers::PrintBoxes.new
        ]
      end
    end
  end
end
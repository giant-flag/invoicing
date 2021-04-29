require 'prawn'

# This class is responsible for generating a pdf for an invoice. It assumes that
# you have installed pdf library called prawn. Just pass an invoice, and call
# render by passing the file.
#
# generator = Invoicing::LedgerItem::PdfGenerator.new(invoice)
# generator.render('/path/to/pdf-file/to/be/generated')
#
module Invoicing
  module LedgerItem
    class PdfGenerator
      def initialize(invoice)
        @invoice = invoice
      end
      attr_reader :invoice

      def render(file)
        Prawn::Document.generate(file) do |pdf|
          render_headers(pdf)
          render_details(pdf)
          render_summary(pdf)
        end
      end

      private

      def render_headers(pdf)
        pdf.table([ ['Invoice Receipt'] ], width: 540, cell_style: {padding: 0}) do
          row(0..10).borders = []
          cells.column(0).style(size: 20, font_style: :bold, valign: :center)
        end
      end

      # Renders details about pdf. Shows recipient name, invoice date and id
      def render_details(pdf)
        pdf.move_down 10
        pdf.stroke_horizontal_rule
        pdf.move_down 15

        billing_details =
          pdf.make_table([ ['Billed to:'], [recipient_name] ],
                         width: 355, cell_style: {padding: 0}) do
          row(0..10).style(size: 9, borders: [])
          row(0).column(0).style(font_style: :bold)
        end

        invoice_date = invoice.created_at.strftime('%e %b %Y')
        invoice_id   = invoice.id.to_s
        invoice_details =
          pdf.make_table([ ['Invoice Date:', invoice_date], ['Invoice No:', invoice_id] ],
                         width: 185, cell_style: {padding: 5, border_width: 0.5}) do
          row(0..10).style(size: 9)
          row(0..10).column(0).style(font_style: :bold)
        end

        pdf.table([ [billing_details, invoice_details] ], cell_style: {padding: 0}) do
          row(0..10).style(borders: [])
        end
      end

      # Renders details of invoice in a tabular format. Renders each line item, and
      # unit price, and total amount, along with tax. It also displays summary,
      # ie total amount, and total price along with tax.
      def render_summary(pdf)
        pdf.move_down 25
        pdf.text 'Invoice Summary', size: 12, style: :bold
        pdf.stroke_horizontal_rule

        table_details = [ ['Sl. no.', 'Description', 'Total Price'] ]
        invoice.line_items.each_with_index do |line_item, index|
          net_amount = line_item.net_amount_formatted
          table_details <<
            [index + 1, line_item.description, net_amount]
        end
        pdf.table(table_details, column_widths: [40, 440, 60], header: true,
                  cell_style: {padding: 5, border_width: 0.5}) do
          row(0).style(size: 10, font_style: :bold)
          row(0..100).style(size: 9)

          cells.columns(0).align = :right
          cells.columns(2).align = :right
          row(0..100).borders = [:top, :bottom]
        end

        summary_details = [
          ['Subtotal', invoice.net_amount_formatted],
          ['Tax',      invoice.tax_amount_formatted],
          ['Total',    invoice.total_amount_formatted]
        ]
        pdf.table(summary_details, column_widths: [480, 60], header: true,
                  cell_style: {padding: 5, border_width: 0.5}) do
          row(0..100).style(size: 9, font_style: :bold)
          row(0..100).borders = []
          cells.columns(0..100).align = :right
        end

        pdf.move_down 25
        pdf.stroke_horizontal_rule
      end

      def recipient_name
        invoice.recipient.respond_to?(:name) ? invoice.recipient.name : ''
      end
    end
  end
end

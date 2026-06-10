import 'package:flutter/widgets.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Salin halaman [startIdx]..[endIdx] (indeks 0-based, inklusif) dari dokumen
/// [src] ke dokumen [out], mempertahankan ukuran tiap halaman.
/// Memakai API resmi Syncfusion: PdfPage.createTemplate + drawPdfTemplate.
void copyPages(PdfDocument src, PdfDocument out, int startIdx, int endIdx) {
  for (var i = startIdx; i <= endIdx; i++) {
    final page = src.pages[i];
    final template = page.createTemplate();
    out.pageSettings.margins.all = 0;
    out.pageSettings.size = page.size;
    out.pages.add().graphics.drawPdfTemplate(template, Offset.zero);
  }
}

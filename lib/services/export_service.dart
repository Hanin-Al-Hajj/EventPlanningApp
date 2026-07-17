import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:event_planner/models/Guest.dart';

class ExportService {
  // ✅ EXPORT TO PDF
  static Future<void> exportToPdf({
    required List<Guest> guests,
    required String eventName,
    required int totalCount,
    required int acceptedCount,
    required int pendingCount,
    required int declinedCount,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            pw.Center(
              child: pw.Text(
                '$eventName - Guest List',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#475B35'),
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Generated on: ${_formatDate(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#EFE7DA'),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _statItem('Total', totalCount, PdfColors.black),
                  _statItem('Accepted', acceptedCount, PdfColors.green),
                  _statItem(
                    'Pending',
                    pendingCount,
                    PdfColor.fromHex('#FF9800'),
                  ),
                  _statItem('Declined', declinedCount, PdfColors.red),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: [
                '#',
                'Name',
                'Email',
                'Phone',
                'Status',
                'Plus One',
                'Dietary',
              ],
              data: guests.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final guest = entry.value;
                return [
                  index.toString(),
                  guest.name,
                  guest.email,
                  guest.phoneNumber,
                  guest.status.name.toUpperCase(),
                  guest.plusOneName ?? 'N/A',
                  guest.dietaryRestrictions ?? 'N/A',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#475B35'),
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellHeight: 24,
              cellAlignments: {
                0: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
              },
              oddRowDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#EFE7DA'),
              ),
            ),
          ],
        ),
      );

      // Convert PDF to base64 and create data URL
      final pdfBytes = await pdf.save();
      final base64Pdf = base64Encode(pdfBytes);

      // This will open directly in Chrome/browser and show the PDF
      final htmlContent =
          '''
        <html>
          <head>
            <title>$eventName - Guest List</title>
          </head>
          <body style="margin:0;padding:0;">
            <embed src="data:application/pdf;base64,$base64Pdf" 
                   type="application/pdf" 
                   width="100%" 
                   height="100%" 
                   style="position:fixed;top:0;left:0;width:100%;height:100%;">
          </body>
        </html>
      ''';

      // Save HTML file temporarily
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'guests_${eventName.replaceAll(RegExp(r'[^\w\s]+'), '_')}_$timestamp.html';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(htmlContent);

      // Open HTML file - this will open in Chrome/browser
      final fileUri = Uri.file(filePath);
      if (await canLaunchUrl(fileUri)) {
        await launchUrl(fileUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: Save as PDF file and share
        final pdfPath =
            '${directory.path}/guests_${eventName.replaceAll(RegExp(r'[^\w\s]+'), '_')}_$timestamp.pdf';
        final pdfFile = File(pdfPath);
        await pdfFile.writeAsBytes(pdfBytes);

        await Share.shareXFiles([
          XFile(pdfPath, mimeType: 'application/pdf'),
        ], subject: '$eventName - Guest List PDF');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ✅ EXPORT TO EXCEL (CSV) - Opens in spreadsheet app
  static Future<void> exportToExcel({
    required List<Guest> guests,
    required String eventName,
  }) async {
    try {
      StringBuffer csv = StringBuffer();
      csv.write('\uFEFF');
      csv.writeln('#,Name,Email,Phone,Status,Plus One,Dietary,Invitation Sent');

      for (int i = 0; i < guests.length; i++) {
        final guest = guests[i];
        csv.writeln(
          '${i + 1},"${guest.name}","${guest.email}","${guest.phoneNumber}","${guest.status.name.toUpperCase()}","${guest.plusOneName ?? 'N/A'}","${guest.dietaryRestrictions ?? 'N/A'}","${guest.invitationSent ? 'Yes' : 'No'}"',
        );
      }

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'guests_${eventName.replaceAll(RegExp(r'[^\w\s]+'), '_')}_$timestamp.csv';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(csv.toString());

      final fileUri = Uri.file(filePath);
      if (await canLaunchUrl(fileUri)) {
        await launchUrl(fileUri, mode: LaunchMode.externalApplication);
      } else {
        await Share.shareXFiles([
          XFile(filePath, mimeType: 'text/csv'),
        ], subject: '$eventName - Guest List Excel');
      }
    } catch (e) {
      rethrow;
    }
  }

  static pw.Widget _statItem(String label, int count, PdfColor color) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          count.toString(),
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

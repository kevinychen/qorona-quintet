package io.github.kevinychen.tools;

import java.awt.Desktop;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.URL;

import org.apache.batik.apps.rasterizer.DestinationType;
import org.apache.batik.apps.rasterizer.SVGConverter;
import org.apache.batik.apps.rasterizer.SVGConverterException;
import org.apache.commons.io.FileUtils;
import org.apache.pdfbox.io.MemoryUsageSetting;
import org.apache.pdfbox.multipdf.PDFMergerUtility;

import com.itextpdf.text.Document;
import com.itextpdf.text.DocumentException;
import com.itextpdf.text.Image;
import com.itextpdf.text.PageSize;
import com.itextpdf.text.pdf.PdfWriter;

class MuseScoreConverter {

    enum FileType {
        PNG, SVG;
    }

    File convertToPdf(String urlFormat, FileType type, int numPages) throws DocumentException, IOException, SVGConverterException {
        PDFMergerUtility merger = new PDFMergerUtility();
        for (int i = 0; i < numPages; i++) {
            URL url = new URL(String.format(urlFormat, i));
            File pdf = File.createTempFile("page-", ".pdf");
            switch (type) {
                case PNG:
                    Document document = new Document(PageSize.LETTER, 0, 0, 0, 0);
                    PdfWriter.getInstance(document, new FileOutputStream(pdf));
                    document.open();
                    Image image = Image.getInstance(url);
                    image.scaleAbsolute(document.getPageSize());
                    document.add(image);
                    document.close();
                    break;
                case SVG:
                    File imageFile = File.createTempFile("page-", "svg");
                    FileUtils.copyURLToFile(url, imageFile);
                    SVGConverter converter = new SVGConverter();
                    converter.setDestinationType(DestinationType.PDF);
                    converter.setSources(new String[] { imageFile.toString() });
                    converter.setDst(pdf);
                    converter.execute();
                    break;
            }

            merger.addSource(pdf);
        }

        File mergedPdf = File.createTempFile("merged-", ".pdf");
        merger.setDestinationFileName(mergedPdf.toString());
        merger.mergeDocuments(MemoryUsageSetting.setupMainMemoryOnly());
        return mergedPdf;
    }

    public static void main(String[] args) throws Exception {
        File pdf = new MuseScoreConverter().convertToPdf(
            "https://musescore.com/static/musescore/scoredata/gen/.../score_%d.png", // from page source
            FileType.PNG,
            1);
        Desktop.getDesktop().open(pdf);
    }
}

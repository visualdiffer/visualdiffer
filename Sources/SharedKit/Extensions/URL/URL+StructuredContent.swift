//
//  URL+StructuredContent.swift
//  VisualDiffer
//
//  Created by davide ficano on 14/06/25.
//  Copyright (c) 2025 visualdiffer.com
//

import UniformTypeIdentifiers
import PDFKit

struct StructuredContentValues {
    let originalType: UTType?
    let contentType: UTType?
    let plainText: String?
    let encoding: String.Encoding?
}

extension URL {
    /**
     * Return the plain text content from current url. If the content is a rich format like
     * Word .doc files the text content is extracted and returned.
     * If the content is a plain text format then use the encoding specified into options (if any)
     * then the NSWindowsCP1252StringEncoding and at least the auto detect offered by NSAttributedString
     * @param options passed to [NSAttributedString initWithURL:url]
     * @param docAttrs passed to [NSAttributedString initWithURL:url]
     * @return the plain text url content on success, nil otherwise
     */
    func readPlainText(
        options: [NSAttributedString.DocumentReadingOptionKey: Any],
        documentAttributes docAttrs: inout [NSAttributedString.DocumentAttributeKey: Any]
    ) throws -> String? {
        if let text = try readHandlingInapplicableStringEncoding(options: options, documentAttributes: &docAttrs) {
            return text.string
        }
        // try fallback encoding NSWindowsCP1252StringEncoding
        let optionsWithBestEncoding = options.merging(
            [.characterEncoding: NSWindowsCP1252StringEncoding]
        ) { _, new in new }

        if let text = try readHandlingInapplicableStringEncoding(
            options: optionsWithBestEncoding,
            documentAttributes: &docAttrs
        ) {
            return text.string
        }
        // try removing encoding
        var optionsWithoutEncoding = options
        optionsWithoutEncoding.removeValue(forKey: .characterEncoding)
        if let text = try readHandlingInapplicableStringEncoding(
            options: optionsWithoutEncoding,
            documentAttributes: &docAttrs
        ) {
            return text.string
        }

        return nil
    }

    private func readHandlingInapplicableStringEncoding(
        options: [NSAttributedString.DocumentReadingOptionKey: Any],
        documentAttributes docAttrs: inout [NSAttributedString.DocumentAttributeKey: Any]
    ) throws -> NSAttributedString? {
        var nsDocAttrs: NSDictionary? = docAttrs as NSDictionary?
        do {
            let text = try NSAttributedString(
                url: self,
                options: options,
                documentAttributes: &nsDocAttrs
            )
            if let nsDocAttrs = nsDocAttrs as? [NSAttributedString.DocumentAttributeKey: Any] {
                docAttrs.merge(nsDocAttrs) { _, new in new }
            }
            return text
        } catch let error as NSError {
            if error.domain == NSCocoaErrorDomain,
               error.code == NSFileReadInapplicableStringEncodingError {
                return nil
            }
            throw error
        }
    }

    func readStructuredContent(encoding: String.Encoding) throws -> StructuredContentValues {
        enum Static {
            static let documentTypeToUTType: [NSAttributedString.DocumentType: UTType] = {
                var mapping: [NSAttributedString.DocumentType: UTType] = [
                    .plain: .plainText,
                    .rtf: .rtf,
                    .rtfd: .rtfd,
                ]

                // add only if are not nil
                mapping[.officeOpenXML] = UTType("org.openxmlformats.wordprocessingml.document")
                mapping[.docFormat] = UTType("com.microsoft.word.doc")

                return mapping
            }()

            static let supportedFormats = Set(documentTypeToUTType.values)
        }
        let values = try resourceValues(forKeys: [.contentTypeKey])
        let fileType = values.contentType

        if let fileType,
           fileType == .pdf {
            let pdfDoc = PDFDocument(url: self)

            return StructuredContentValues(
                originalType: fileType,
                contentType: fileType,
                plainText: pdfDoc?.string,
                encoding: nil
            )
        }

        let usePlainText = if let fileType {
            !Static.supportedFormats.contains(fileType)
        } else {
            true
        }

        var options = [NSAttributedString.DocumentReadingOptionKey: Any]()

        // NSAttributedString parses HTML files but we want to show the source
        // code so we force plain type for other supported formats
        if usePlainText {
            options[.documentType] = NSAttributedString.DocumentType.plain
        }
        options[.characterEncoding] = NSNumber(value: encoding.rawValue)

        var docAttrs = [NSAttributedString.DocumentAttributeKey: Any]()
        let content = try readPlainText(
            options: options,
            documentAttributes: &docAttrs
        )

        let docEnconding: String.Encoding? = if let enc = docAttrs[.characterEncoding] as? NSNumber {
            String.Encoding(rawValue: enc.uintValue)
        } else {
            nil
        }
        let contentType: UTType? = if let contentType = docAttrs[.documentType] as? NSAttributedString.DocumentType {
            Static.documentTypeToUTType[contentType]
        } else {
            nil
        }

        return StructuredContentValues(
            originalType: fileType,
            contentType: contentType,
            plainText: content,
            encoding: docEnconding
        )
    }
}

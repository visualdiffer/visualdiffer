//
//  DatePickersStackView.swift
//  VisualDiffer
//
//  Created by davide ficano on 04/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

class DatePickersStackView: NSStackView, NSDatePickerCellDelegate {
    enum PickerType {
        case date
        case time
    }

    private var isDateChanging = false

    private let textualPicker: NSDatePicker
    private let graphicalPicker: NSDatePicker

    var dateValue: Date {
        get {
            textualPicker.dateValue
        }

        set {
            textualPicker.dateValue = newValue
            graphicalPicker.dateValue = newValue
        }
    }

    var isEnabled: Bool {
        get {
            textualPicker.isEnabled
        }

        set {
            textualPicker.isEnabled = newValue
            graphicalPicker.isEnabled = newValue
        }
    }

    private(set) var type: PickerType

    init(type: DatePickersStackView.PickerType) {
        self.type = type

        textualPicker = NSDatePicker()
        graphicalPicker = NSDatePicker()

        super.init(frame: .zero)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        textualPicker.delegate = self
        graphicalPicker.delegate = self

        switch type {
        case .date:
            textualPicker.datePickerStyle = .textFieldAndStepper
            textualPicker.datePickerElements = .yearMonthDay

            graphicalPicker.datePickerStyle = .clockAndCalendar
            graphicalPicker.datePickerElements = .yearMonthDay
        case .time:
            textualPicker.datePickerStyle = .textFieldAndStepper
            textualPicker.datePickerElements = .hourMinuteSecond

            graphicalPicker.datePickerStyle = .clockAndCalendar
            graphicalPicker.datePickerElements = .hourMinuteSecond
        }

        addArrangedSubview(textualPicker)
        addArrangedSubview(graphicalPicker)

        orientation = .vertical
        alignment = .centerX
        spacing = 10
        translatesAutoresizingMaskIntoConstraints = false
    }

    func components(calendar: NSCalendar) -> DateComponents {
        switch type {
        case .date:
            calendar.components([.day, .month, .year], from: textualPicker.dateValue)
        case .time:
            calendar.components([.hour, .minute, .second], from: textualPicker.dateValue)
        }
    }

    func datePickerCell(
        _ datePickerCell: NSDatePickerCell,
        validateProposedDateValue proposedDateValue:
        AutoreleasingUnsafeMutablePointer<NSDate>,
        timeInterval _: UnsafeMutablePointer<TimeInterval>?
    ) {
        if isDateChanging {
            return
        }
        isDateChanging = true

        // sync graphical and textual pickers
        let date = proposedDateValue.pointee as Date
        if datePickerCell === graphicalPicker.cell {
            textualPicker.dateValue = date
        } else if datePickerCell === textualPicker.cell {
            graphicalPicker.dateValue = date
        }
        isDateChanging = false
    }
}

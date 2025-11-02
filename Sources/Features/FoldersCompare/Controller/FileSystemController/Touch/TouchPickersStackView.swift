//
//  TouchPickersStackView.swift
//  VisualDiffer
//
//  Created by davide ficano on 04/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

class TouchPickersStackView: NSStackView {
    private let datePickers: DatePickersStackView
    private let timePickers: DatePickersStackView

    var isEnabled: Bool {
        get {
            datePickers.isEnabled
        }

        set {
            datePickers.isEnabled = newValue
            timePickers.isEnabled = newValue
        }
    }

    var touchDate: Date? {
        get {
            guard let gregorian = NSCalendar(calendarIdentifier: .gregorian) else {
                return nil
            }
            var dateComponents = datePickers.components(calendar: gregorian)
            let timeComponents = timePickers.components(calendar: gregorian)

            dateComponents.hour = timeComponents.hour
            dateComponents.minute = timeComponents.minute
            dateComponents.second = timeComponents.second

            return gregorian.date(from: dateComponents)
        }

        set {
            if let newValue {
                datePickers.dateValue = newValue
                timePickers.dateValue = newValue
            }
        }
    }

    init() {
        datePickers = DatePickersStackView(type: .date)
        timePickers = DatePickersStackView(type: .time)

        super.init(frame: .zero)

        setupViews()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        orientation = .horizontal
        alignment = .centerY
        spacing = 10
        translatesAutoresizingMaskIntoConstraints = false

        addArrangedSubview(datePickers)
        addArrangedSubview(timePickers)

        // move timePickers to the top so textual fields are aligned
        NSLayoutConstraint.activate([
            timePickers.topAnchor.constraint(equalTo: topAnchor),
        ])
    }
}

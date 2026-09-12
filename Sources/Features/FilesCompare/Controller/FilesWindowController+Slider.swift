//
//  FilesWindowController+Slider.swift
//  VisualDiffer
//
//  Created by davide ficano on 01/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

extension FilesWindowController {
    @objc
    func sliderMoved(_ sender: AnyObject) {
        let other = sender === leftPanelView.columnSlider ? rightPanelView.columnSlider : leftPanelView.columnSlider
        other.doubleValue = sender.doubleValue

        leftView.reloadData(restoreSelection: true)
        rightView.reloadData(restoreSelection: true)
    }

    func setSliderMaxValue() {
        guard let diffResult else {
            return
        }

        // both panels share the same value, computing it once per panel used to be the
        // longest blocking step of a comparison
        let maxColumn = widestColumn(
            leftLines: diffResult.leftSide.lines,
            rightLines: diffResult.rightSide.lines
        )

        leftPanelView.setSliderMaxValue(maxColumn)
        rightPanelView.setSliderMaxValue(maxColumn)
    }

    private func widestColumn(
        leftLines: [DiffLine],
        rightLines: [DiffLine]
    ) -> Int {
        var widest = 0

        // walking each side on its own does not depend on the two being aligned,
        // an edit can leave them with a different number of lines
        for line in leftLines {
            widest = max(widest, line.text.count)
        }

        for line in rightLines {
            widest = max(widest, line.text.count)
        }

        return widest
    }
}

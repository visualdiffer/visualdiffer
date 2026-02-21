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

    @objc
    func setSliderMaxValue() {
        guard let diffResult else {
            return
        }
        leftPanelView.setSliderMaxValue(
            diffResult.leftSide.lines,
            right: diffResult.rightSide.lines
        )
        rightPanelView.setSliderMaxValue(
            diffResult.leftSide.lines,
            right: diffResult.rightSide.lines
        )
    }
}

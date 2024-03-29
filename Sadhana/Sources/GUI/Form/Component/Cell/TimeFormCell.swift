//
//  DateFormCell.swift
//  Sadhana
//
//  Created by Alexander Koryttsev on 7/20/17.
//  Copyright © 2017 Alexander Koryttsev. All rights reserved.
//


import EasyPeasy


class TimeKeyboardFormCell: CountsLayoutCell, UITextFieldDelegate {
    private let viewModel: DataFormFieldVM<Time?>
    private var hoursView: CountView {
        get {
            return countViews.first!
        }
    }
    private var minutesView: CountView {
        get {
            return countViews.last!
        }
    }
    
    override var isFilled: Bool {
        return viewModel.variable.value != nil
    }

    init(_ viewModel: DataFormFieldVM<Time?>) {
        self.viewModel = viewModel
        super.init(fieldsCount:2)

        if let value = viewModel.variable.value {
            if value.rawValue > 0 {
                hoursView.valueField.text = value.hourString
                minutesView.valueField.text = value.minuteString
            }
        }

        titleLabel.text = viewModel.title.localized

        setUp(field: hoursView.valueField)
        hoursView.titleLabel.text = "hours".localized

        setUp(field: minutesView.valueField)
        minutesView.titleLabel.text = "minutes".localized

        Driver.combineLatest(hoursView.valueField.rx.textRequired.asDriver(), minutesView.valueField.rx.textRequired.asDriver()).map({(hours, minutes) -> Time? in
            return Time(hour:hours, minute:minutes)
        })
            .distinctUntilChanged({ (time1, time2) -> Bool in
                if let time1 = time1,
                    let time2 = time2 {
                    return time1.rawValue == time2.rawValue
                }

                if time1 == nil,
                    time2 == nil {
                    return true
                }

                return false
            })
            .skip(1)
            .drive(viewModel.variable)
            .disposed(by: disposeBag)
    }

    func setUp(field:UITextField) {
        field.delegate = self
        field.placeholder = "00"
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let textField = textField as! NumberField
        let nsString = textField.text as NSString?
        if let resultString = nsString?.replacingCharacters(in: range, with: string) {
            if resultString.isEmpty {
                return true
            }

            if resultString.count > 2  {
                return false
            }

            if let number = Int(resultString) {
                if textField == hoursView.valueField {
                    if (0..<24).contains(number) {
                        if number > 2 ||
                            resultString.count == 2 {
                            DispatchQueue.main.async {
                                textField.goNext.onNext(())
                            }
                        }
                        return true
                    }
                    else if (24..<26).contains(number) {
                        textField.goNext.onNext(())
                    }
                    return false
                }
                if textField == minutesView.valueField,
                    (0..<60).contains(number) {
                    if number > 5 ||
                        resultString.count == 2 {
                        DispatchQueue.main.async {
                            self.goNext.onNext(())
                        }
                    }
                    return true
                }
            }
        }

        return false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//
//  TextFieldFormCell.swift
//  Sadhana
//
//  Created by Alexander Koryttsev on 11/18/17.
//  Copyright © 2017 Alexander Koryttsev. All rights reserved.
//


import EasyPeasy


class TextFieldFormCell: FormCell, ResponsibleContainer, Validable {

    let type : TextFieldType
    let titleLabel = UILabel()
    let textField = TextField()
    var responsible: Responsible {
        return textField
    }

    override var isFilled : Bool {
        return viewModel.variable.value.count > 0
    }
    
    let beginValidation = PublishSubject<Void>()

    let viewModel : DataFormFieldVM<String>
    let disposeBag = DisposeBag()

    init(_ viewModel: DataFormFieldVM<String>) {
        self.viewModel = viewModel

        switch viewModel.type {
            case .text(let fieldType):
                type = fieldType
                switch fieldType {
                    case .name(let nameType):
                        textField.autocapitalizationType = .words
                            switch(nameType) {
                                case .first: textField.textContentType = .name;     break
                                case .last: textField.textContentType = .familyName; break
                                default: break
                            }
                        break
                    case .email:
                        textField.keyboardType = .emailAddress
                        textField.textContentType = .emailAddress
                        break
                    case .password:
                        textField.isSecureTextEntry = true
                        if #available(iOS 11, *) {
                            textField.textContentType = .password
                        }
                        break
                    default: break
                }
            default:
                fatalError("Can't create TextFieldFormCell with\(viewModel.type), only FormFieldType.text allowed")
                break
        }

        super.init(style: .default, reuseIdentifier: TextFieldFormCell.classString)

        titleLabel.text = viewModel.title.localized
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.regular)
        contentView.addSubview(titleLabel)
        titleLabel.easy.layout([
            Left(15),
            CenterY()
        ])

        reloadData()

        if let validDriver = viewModel.valid {
            var beginValidation = textField.rx.controlEvent(.editingDidEnd).take(1).asDriver(onErrorJustReturn: ())
            if let viewModelBeginValidation = viewModel.beginValidation {
                beginValidation = Driver.merge(beginValidation, viewModelBeginValidation)
            }
            
            Driver.combineLatest(beginValidation, validDriver, resultSelector: { [unowned self] (_, valid) -> Void in
                self.set(valid:valid)
            }).drive().disposed(by: disposeBag)
        }

        textField.rx.textRequired.bind(to:viewModel.variable).disposed(by: disposeBag)
        textField.isEnabled = viewModel.enabled
        textField.textAlignment = viewModel.enabled ? .left : .right
        textField.textColor = viewModel.enabled ? .black : .sdSteel
        textField.returnKeyType = .next
        textField.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)
        contentView.addSubview(textField)
        textField.easy.layout([
            Left(10).to(titleLabel, .right),
            CenterY(),
            Width(*0.5).like(contentView),
            Right(viewModel.enabled ? 16 : 37)
        ])

        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            becomeActive.onNext(())
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
    
    override func reloadData() {
        textField.text = viewModel.variable.value
    }
}

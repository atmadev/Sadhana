//
//  EntryEditingVC.swift
//  Sadhana
//
//  Created by Alexander Koryttsev on 7/19/17.
//  Copyright © 2017 Alexander Koryttsev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class EntryEditingVC : BaseTableVC<EntryEditingVM> {
    var cells = [FormCell]()

    override func viewDidLoad() {
        automaticallyAdjustsScrollViewInsets = false
        super.viewDidLoad()
        tableView.contentInset = UIEdgeInsetsMake(iOS(11) ? 108 : 128, 0, 50, 0)
        tableView.keyboardDismissMode = .onDrag
        tableView.tableFooterView = UIView()
        tableView.showsVerticalScrollIndicator = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.row]
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cells[indexPath.row].height()
    }

    override func bindViewModel() {
        super.bindViewModel()

        var previousResponsibleCell : ResponsibleCell?
        var firstResponsibleCell : ResponsibleCell?
        for field in viewModel.fields {
            var currentCell : FormCell?
            if let field = field as? VariableField<Time?> {
                currentCell = TimeKeyboardFormCell(field)
            }
            else if let field = field as? FieldsContainer<Int16> {
                currentCell = CountContainerCell(field)
            }
            else if let field = field as? VariableField<Bool> {
                currentCell = BoolFormCell(field)
            }

            if let currentCell = currentCell {
                cells.append(currentCell)

                if let currentResponsibleCell = currentCell as? ResponsibleCell {
                    if let previousResponsibleCell = previousResponsibleCell {

                        previousResponsibleCell.resignActive.filter({ (isNext) -> Bool in
                            return isNext
                        }).bind(to: currentResponsibleCell.becomeActive).disposed(by: disposeBag)

                        currentResponsibleCell.resignActive.filter({(isNext) -> Bool in
                            return !isNext
                        }).bind(to: previousResponsibleCell.becomeActive).disposed(by: disposeBag)
                    }
                    previousResponsibleCell = currentResponsibleCell

                    if firstResponsibleCell == nil {
                        firstResponsibleCell = currentResponsibleCell
                    }
                }
            }
        }

        if let firstResponsibleCell = firstResponsibleCell {
            firstResponsibleCell.resignActive.subscribe(onNext:{ [weak self] (isNext) in
                if !isNext {
                    self?.tableView.endEditing(true)
                }
            }).disposed(by: disposeBag)
        }

        if let lastResponsibleCell = previousResponsibleCell {
            lastResponsibleCell.resignActive.subscribe(onNext:{ [weak self] (isNext) in
                if isNext {
                    self?.tableView.endEditing(true)
                }
            }).disposed(by: disposeBag)
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if !editing {
            tableView.endEditing(true)
        }
    }
}

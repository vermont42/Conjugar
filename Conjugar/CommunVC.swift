//
//  CommunVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 12/13/20.
//  Copyright © 2020 Josh Adams. All rights reserved.
//

import UIKit

class CommunVC: UIViewController {
  var communView: CommunUIV {
    if let castedView = view as? CommunUIV {
      return castedView
    } else {
      fatalError(fatalCastMessage(view: CommunUIV.self))
    }
  }

  var viewModel: CommunViewModel?
  var unitTestCompletion: (() -> ())?
  private let unknownIdentifier = -42

  init(commun: Commun) {
    super.init(nibName: nil, bundle: nil)
    viewModel = CommunViewModel(commun: commun)
  }

  required init?(coder aDecoder: NSCoder) {
    NSCoder.fatalErrorNotImplemented()
  }

  override func loadView() {
    let communView: CommunUIV
    communView = CommunUIV(frame: UIScreen.main.bounds)
    communView.closeButton.addTarget(self, action: #selector(tapClose), for: .touchUpInside)
    communView.okayButton.addTarget(self, action: #selector(tapOkay), for: .touchUpInside)
    communView.actionButton.addTarget(self, action: #selector(tapAction), for: .touchUpInside)
    communView.cancelButton.addTarget(self, action: #selector(tapCancel), for: .touchUpInside)
    view = communView
    configureUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if let identifier = viewModel?.identifier {
      Current.analytics.recordCommunVisitation(identifier: identifier)
    }
  }

  private func configureUI() {
    guard let viewModel = viewModel else {
      fatalError("\(CommunViewModel.self) not initialized.")
    }

    communView.title.text = viewModel.title
    communView.content.text = viewModel.content
    communView.imageView.image = viewModel.image
    communView.imageView.accessibilityLabel = viewModel.imageLabel
    communView.okayButton.isHidden = !viewModel.shouldShowOkay
    communView.okayButton.setTitle(viewModel.okayTitle, for: .normal)
    communView.cancelButton.isHidden = !viewModel.shouldShowCancel
    communView.cancelButton.setTitle(viewModel.cancelTitle, for: .normal)
    communView.actionButton.isHidden = !viewModel.shouldShowAction
    communView.actionButton.setTitle(viewModel.actionTitle, for: .normal)
  }

  @objc func tapClose() {
    Current.analytics.recordCloseTap(identifier: viewModel?.identifier ?? unknownIdentifier)
    dismiss(animated: true, completion: unitTestCompletion)
  }

  @objc func tapOkay() {
    Current.analytics.recordOkayTap(identifier: viewModel?.identifier ?? unknownIdentifier)
    dismiss(animated: true, completion: unitTestCompletion)
  }

  @objc func tapAction() {
    Current.analytics.recordActionTap(identifier: viewModel?.identifier ?? unknownIdentifier)
    SoundPlayer.playRandomApplause()
    dismiss(animated: true, completion: { [weak self] in
      self?.viewModel?.action()
      self?.unitTestCompletion?()
    })
  }

  @objc func tapCancel() {
    Current.analytics.recordCancelTap(identifier: viewModel?.identifier ?? unknownIdentifier)
    dismiss(animated: true, completion: unitTestCompletion)
  }
}

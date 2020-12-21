//
//  CommunUIV.swift
//  Conjugar
//
//  Created by Joshua Adams on 12/13/20.
//  Copyright © 2020 Josh Adams. All rights reserved.
//

import UIKit

class CommunUIV: UIView {
  @UsesAutoLayout
  var closeButton: UIButton = {
    let closeButton = UIButton()
    let configuration = UIImage.SymbolConfiguration(pointSize: 24)
    let xImage = UIImage(systemName: "xmark.square.fill", withConfiguration: configuration)?.withTintColor(Colors.red, renderingMode: .alwaysOriginal)
    closeButton.setImage(xImage, for: .normal)
    return closeButton
  }()

  @UsesAutoLayout var title: UILabel = {
    let title = UILabel()
    title.textColor = Colors.yellow
    title.font = Fonts.heading
    title.text = "Tonkinese"
    title.numberOfLines = 0
    title.textAlignment = .center
    title.accessibilityTraits = [.header]
    return title
  }()

  @UsesAutoLayout
  var imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.image = UIImage(named: "Dancer")
    imageView.isAccessibilityElement = true
    imageView.accessibilityTraits = []
    return imageView
  }()

  @UsesAutoLayout
  var content: UITextView = {
    let content = UITextView()
    content.backgroundColor = Colors.black
    content.textColor = Colors.yellow
    content.tintColor = Colors.blue
    content.isEditable = false
    content.font = Fonts.body
    content.text = tonkText
    return content
  }()

  @UsesAutoLayout
  var cancelButton = CommunUIV.createButton(title: "No Thanks")

  @UsesAutoLayout
  var okayButton = CommunUIV.createButton(title: "Okay")

  @UsesAutoLayout
  var actionButton = CommunUIV.createButton(title: "Adopt One")

  override init(frame: CGRect) {
    super.init(frame: frame)
    [closeButton, title, imageView, content, cancelButton, okayButton, actionButton].forEach {
      addSubview($0)
    }

    NSLayoutConstraint.activate([
      closeButton.widthAnchor.constraint(equalToConstant: 40),
      closeButton.heightAnchor.constraint(equalToConstant: 40),
      closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
      closeButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),

      title.topAnchor.constraint(equalTo: closeButton.bottomAnchor),
      title.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      title.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),

      imageView.topAnchor.constraint(equalTo: title.bottomAnchor, constant: Layout.defaultSpacing),
      imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
      imageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5),
      imageView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5),

      content.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: Layout.defaultSpacing),
      content.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      content.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),

      cancelButton.topAnchor.constraint(equalTo: content.bottomAnchor, constant: Layout.defaultSpacing),
      cancelButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      cancelButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),

      okayButton.topAnchor.constraint(equalTo: content.bottomAnchor, constant: Layout.defaultSpacing),
      okayButton.centerXAnchor.constraint(equalTo: centerXAnchor),
      okayButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),

      actionButton.topAnchor.constraint(equalTo: content.bottomAnchor, constant: Layout.defaultSpacing),
      actionButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
      actionButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
    ])
  }

  required init(coder aDecoder: NSCoder) {
    NSCoder.fatalErrorNotImplemented()
  }

  private static func createButton(title: String) -> UIButton {
    let button = UIButton()
    button.setTitle(title, for: .normal)
    button.setTitleColor(Colors.red, for: .normal)
    button.titleLabel?.font = Fonts.button
    button.sizeToFit()
    return button
  }
}

let tonkText = """
Tonkinese are a domestic cat breed produced by crossbreeding between the Siamese and Burmese. They share many of their parents' distinctively lively, playful personality traits and are similarly distinguished by a pointed coat pattern in a variety of colors. In addition to the modified coat colors of the "mink" pattern, which is a dilution of the point color (as in watercolors), the breed is now being shown in the foundation-like Siamese and Burmese colors: pointed with white and Solid overall (sepia.) They are also now designated a natural breed, as their history has now determined them to have been extant since the 14th century.
The best known variety is the short-haired Tonkinese, but there is a medium-haired (sometimes called Tibetan) which tends to be more popular in Europe, mainly in the Netherlands, Germany, Belgium and France.
Tonkinese are a medium-sized cat, considered an intermediate type between the slender, long-bodied modern Siamese and British Burmese and the more "cobby", or substantially-built American Burmese. Like their Burmese ancestors, they are deceptively muscular and typically seem much heavier than expected when picked up. Tail and legs are slim but proportionate to the body, with distinctive oval paws. They have a gently rounded, slightly wedge-shaped head and blunted muzzle, with moderately almond-shaped eyes and ears set towards the outside of their head. The American style is a rounder but sculpted head with a shorter body and sturdier appearance to reflect the old-fashioned Siamese and rounded Burmese from which it was originally bred in the United States. While many American breeders avoided using the extreme "contemporary" Burmese in favor of the more moderate "traditional" Burmese, the original Tonkinese breed standard was based on the extreme spherical style of the Burms descended from Wong Mau. Newer Tonk breeders wanted to avoid defective genes in the original Burmese lines, so avoided using cats they believed carried the so-called lethal genes. A very few older breeders simply worked around the problem by selective breeding, thereby eliminating problematic births. It is possible to find some descendants by knowledgeably reading Tonkinese pedigrees, which are available in Tonkinese databases.
"""

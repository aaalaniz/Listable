//
//  FloatingBottomKeyboardAvoidanceViewController.swift
//  Demo
//
//  Created by Rob MacEachern on 5/15/26.
//  Copyright © 2026 Kyle Van Essen. All rights reserved.
//

import BlueprintUI
import BlueprintUICommonControls
import BlueprintUILists
import ListableUI
import UIKit

final class FloatingBottomKeyboardAvoidanceViewController: UIViewController {
    private let listView = ListView()
    private let floatingBar = FloatingBottomBarView()

    private var floatingBarBottomConstraint: NSLayoutConstraint!
    private var keyboardDismissMode: UIScrollView.KeyboardDismissMode = .none

    private let floatingBarHeight: CGFloat = 112.0

    override func loadView() {
        view = UIView()
        view.backgroundColor = .white

        listView.translatesAutoresizingMaskIntoConstraints = false
        floatingBar.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(listView)
        view.addSubview(floatingBar)

        floatingBarBottomConstraint = floatingBar.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor
        )

        NSLayoutConstraint.activate([
            listView.topAnchor.constraint(equalTo: view.topAnchor),
            listView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            listView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            listView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            floatingBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            floatingBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            floatingBarBottomConstraint,
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Floating Bottom Keyboard"

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Dismiss", style: .plain, target: self, action: #selector(dismissKeyboard)),
            UIBarButtonItem(title: "Mode", style: .plain, target: self, action: #selector(toggleKeyboardDismissMode)),
            UIBarButtonItem(title: "Position", style: .plain, target: self, action: #selector(positionTextAreaForFocus)),
        ]

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )

        configureList()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func toggleKeyboardDismissMode() {
        switch keyboardDismissMode {
        case .none:
            keyboardDismissMode = .interactive
        case .interactive:
            keyboardDismissMode = .onDrag
        default:
            keyboardDismissMode = .none
        }

        configureList()
    }

    @objc private func positionTextAreaForFocus() {
        listView.scrollTo(
            item: DemoTextAreaContent.identifier(with: "note-text-area"),
            position: ScrollPosition(position: .bottom, ifAlreadyVisible: .scrollToPosition, offset: -floatingBarHeight),
            animated: true
        )
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return
        }

        let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
        let keyboardOverlap = max(0.0, view.bounds.maxY - keyboardFrameInView.minY)
        let bottomOffset = max(0.0, keyboardOverlap - view.safeAreaInsets.bottom)

        let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        let curveRawValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int ?? UIView.AnimationCurve.easeInOut.rawValue
        let options = UIView.AnimationOptions(rawValue: UInt(curveRawValue << 16))

        floatingBarBottomConstraint.constant = -bottomOffset

        UIView.animate(
            withDuration: duration,
            delay: 0.0,
            options: options,
            animations: {
                self.view.layoutIfNeeded()
            },
            completion: nil
        )
    }

    private func configureList() {
        listView.configure { list in
            list.appearance = .demoAppearance

            list.layout = .table { layout in
                layout.stickySectionHeaders = false
                layout.bounds = .init(
                    padding: UIEdgeInsets(top: 220.0, left: 20.0, bottom: self.floatingBarHeight + 24.0, right: 20.0),
                    width: .atMost(600.0)
                )

                layout.layout = .init(
                    headerToFirstSectionSpacing: 0.0,
                    interSectionSpacingWithNoFooter: 40.0,
                    interSectionSpacingWithFooter: 40.0,
                    sectionHeaderBottomSpacing: 16.0,
                    itemSpacing: 10.0,
                    itemToSectionFooterSpacing: 0.0
                )
            }

            list.behavior.keyboardDismissMode = self.keyboardDismissMode
            list.behavior.keyboardAdjustmentMode = .adjustsWhenVisible
            list.behavior.keyboardAdjustmentAdditionalInsets = UIEdgeInsets(
                top: 0.0,
                left: 0.0,
                bottom: self.floatingBarHeight,
                right: 0.0
            )

            list.add {
                Section("choices") {
                    DemoChoiceContent(
                        identifierValue: "regular",
                        title: "Regular",
                        detail: "$13.00"
                    )

                    DemoChoiceContent(
                        identifierValue: "small",
                        title: "Small",
                        detail: "$12.00"
                    )

                    DemoChoiceContent(
                        identifierValue: "beef",
                        title: "Beef",
                        isSelected: true
                    )

                    DemoChoiceContent(
                        identifierValue: "chicken",
                        title: "Chicken"
                    )

                    DemoChoiceContent(
                        identifierValue: "tofu",
                        title: "Tofu"
                    )
                } header: {
                    DemoPlainSectionHeader(title: "Protein Choice")
                }

                Section("notes") {
                    Item(
                        DemoTextAreaContent(
                            identifierValue: "note-text-area",
                            placeholder: "Add an item note..."
                        ),
                        sizing: .fixed(height: 180.0)
                    )
                } header: {
                    DemoPlainSectionHeader(title: "Note")
                }

                Section("fulfillment") {
                    for index in 1 ... 8 {
                        DemoChoiceContent(
                            identifierValue: "fulfillment-\(index)",
                            title: index == 1 ? "For Here" : "Additional row \(index)"
                        )
                    }
                } header: {
                    DemoPlainSectionHeader(title: "Fulfillment methods")
                }
            }
        }
    }
}

private final class FloatingBottomBarView: UIView {
    private let stepper = UILabel()
    private let doneButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .white

        stepper.text = "-        1        +"
        stepper.textAlignment = .center
        stepper.font = .systemFont(ofSize: 20.0, weight: .medium)
        stepper.layer.borderColor = UIColor(white: 0.85, alpha: 1.0).cgColor
        stepper.layer.borderWidth = 1.0
        stepper.layer.cornerRadius = 28.0
        stepper.layer.masksToBounds = true

        doneButton.setTitle("Done", for: .normal)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 20.0, weight: .bold)
        doneButton.backgroundColor = .black
        doneButton.layer.cornerRadius = 28.0
        doneButton.layer.masksToBounds = true

        let stack = UIStackView(arrangedSubviews: [stepper, doneButton])
        stack.axis = .horizontal
        stack.spacing = 16.0
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16.0),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.0),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16.0),
            stack.heightAnchor.constraint(equalToConstant: 56.0),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct DemoPlainSectionHeader: BlueprintHeaderFooterContent, Equatable {
    var title: String

    var elementRepresentation: Element {
        Label(text: title) {
            $0.font = .systemFont(ofSize: 24.0, weight: .bold)
            $0.color = .black
        }
        .inset(horizontal: 4.0)
    }
}

private struct DemoChoiceContent: BlueprintItemContent, Equatable {
    var identifierValue: String
    var title: String
    var detail: String?
    var isSelected: Bool = false

    func element(with _: ApplyItemContentInfo) -> Element {
        Row { row in
            row.verticalAlignment = .center

            row.add(child: Label(text: self.title) {
                $0.font = .systemFont(ofSize: 22.0, weight: .semibold)
                $0.color = .black
            })

            row.addFlexible(child: Spacer(width: 1.0))

            if let detail = self.detail {
                row.add(child: Label(text: detail) {
                    $0.font = .systemFont(ofSize: 18.0, weight: .regular)
                    $0.color = .black
                })
            }
        }
        .inset(horizontal: 16.0, vertical: 24.0)
        .box(
            background: UIColor(white: 0.94, alpha: 1.0),
            corners: .rounded(radius: 8.0),
            borders: isSelected ? .solid(color: .black, width: 2.0) : .none
        )
    }
}

private struct DemoTextAreaContent: BlueprintItemContent, Equatable {
    var identifierValue: String
    var placeholder: String

    func element(with _: ApplyItemContentInfo) -> Element {
        DemoTextAreaElement(placeholder: placeholder)
            .box(
                background: .white,
                corners: .rounded(radius: 8.0),
                borders: .solid(color: .black, width: 2.0)
            )
    }
}

private struct DemoTextAreaElement: UIViewElement {
    var placeholder: String

    func makeUIView() -> DemoTextAreaView {
        DemoTextAreaView()
    }

    func updateUIView(_ view: DemoTextAreaView, with _: UIViewElementContext) {
        view.placeholder = placeholder
    }
}

private final class DemoTextAreaView: UIView {
    let textView = UITextView()
    private let placeholderLabel = UILabel()

    var placeholder: String = "" {
        didSet {
            self.placeholderLabel.text = self.placeholder
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        textView.backgroundColor = .clear
        textView.font = .systemFont(ofSize: 20.0, weight: .semibold)
        textView.textContainerInset = UIEdgeInsets(top: 44.0, left: 16.0, bottom: 16.0, right: 16.0)
        textView.isScrollEnabled = false
        textView.accessibilityIdentifier = "Floating Bottom Keyboard Demo Text Area"

        placeholderLabel.font = .systemFont(ofSize: 20.0, weight: .semibold)
        placeholderLabel.textColor = .darkGray

        textView.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(textView)
        addSubview(placeholderLabel)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor),

            placeholderLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20.0),
            placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20.0),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

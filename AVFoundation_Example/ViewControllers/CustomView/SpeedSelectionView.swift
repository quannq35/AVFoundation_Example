//
//  SpeedSelectionView.swift
//  AVFoundation_Example
//
//  Created by Quân Nguyễn on 20/3/25.
//

import UIKit

class SpeedSelectionView: UIView {
    var speedSelected: ((Float) -> ())?
    private let speeds: [Float] = [0.5, 1.0, 1.5, 2.0]
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually

        stackView.spacing = 8
        return stackView
    }()
    
    private func setupView() {
        self.backgroundColor = .white
        self.layer.cornerRadius = 8
        self.clipsToBounds = true
        self.addSubview(stackView)
        
        stackView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(10)
        }
        
        for speed in speeds {
            let button = UIButton()
            button.setTitle("\(speed)x", for: .normal)
            button.setTitleColor(.black, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            button.backgroundColor = .clear
            button.addTarget(self, action: #selector(speedTapped), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }
    }
    
    @objc private func speedTapped(_ sender: UIButton) {
           guard let title = sender.currentTitle, let speed = Float(title.dropLast()) else { return }
           speedSelected?(speed)
       }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

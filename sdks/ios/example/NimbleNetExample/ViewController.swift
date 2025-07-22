/*
 * SPDX-FileCopyrightText: (C) 2025 DeliteAI Authors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import UIKit
import DeliteAI
import SwiftProtobuf

class ViewController: UIViewController {
    
    private let runButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Run LLM", for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        initializeNimbleNet()
    }

    private func setupUI() {
        view.addSubview(runButton)
        runButton.addTarget(self, action: #selector(runLLM), for: .touchUpInside)
        NSLayoutConstraint.activate([
            runButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            runButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func initializeNimbleNet() {
        let config = NimbleNetConfig(
            clientId: "testclient",
            clientSecret: BundleConfig.clientSecret,
            host: BundleConfig.host,
            deviceId: "hello-ios",
            debug: true,
            compatibilityTag: "proto-test",
            online: true
        )
        
        let initialized = NimbleNetApi.initialize(config: config)
        print("isInitialized? \(initialized)")

        DispatchQueue.global().async {
            while !NimbleNetApi.isReady().status {
                print("Waiting for model to be ready...")
                Thread.sleep(forTimeInterval: 1)
            }
            print("Model is ready")
        }
    }

    @objc private func runLLM() {
        DispatchQueue.global().async {
            self.runSequence(prompts: [
                "Hello my name is Arpit and I am a big fan of Indian Cricket team.",
                "Tell me who is the best indian bolwer in cricket history.",
                "And what about the best batsmen ?"
            ])
        }
    }

    private func runSequence(prompts: [String]) {
        
        for prompt in prompts {
            let output = callModel(prompt: prompt)
            print("---- \n Prompt: \(prompt) \n Response: \(output) \n ---" )
        }

        clearPrompt()
    }

    private func callModel(prompt: String) -> String {
        let modelInputs: [String: NimbleNetTensor] = [
            "query": NimbleNetTensor(data: prompt, datatype: .string, shape: nil)
        ]
        _ = NimbleNetApi.runMethod(methodName: "prompt_llm", inputs: modelInputs)

        var outputString = ""

        while true {
            let response = NimbleNetApi.runMethod(methodName: "get_next_str", inputs: [:])
            guard let payload = response.payload else {
                print("No payload received")
                break
            }

            var outputMap: [String: NimbleNetTensor] = [:]
            for (key, value) in payload.map {
                outputMap[key] = NimbleNetTensor(
                    data: value.data,
                    datatype: value.type,
                    shape: value.shape
                )
            }

            if let isFinished = outputMap["finished"] {
                break
            }

            if let str = outputMap["str"]?.data as? String, !str.isEmpty {
                outputString += str
            }

            Thread.sleep(forTimeInterval: 0.2)
        }
        
        return outputString
    }

    private func clearPrompt() {
        let emptyContext: [Int32] = []
        let input: [String: NimbleNetTensor] = [
            "context": NimbleNetTensor(
                data: emptyContext,
                datatype: .int32,
                shape: [emptyContext.count]
            )
        ]
        _ = NimbleNetApi.runMethod(methodName: "clear_prompt", inputs: input)
    }
}

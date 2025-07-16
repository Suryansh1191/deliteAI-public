/*
 * SPDX-FileCopyrightText: (C) 2025 DeliteAI Authors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import UIKit
import DeliteAI
import SwiftProtobuf

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let runButton = UIButton(type: .system)
                runButton.setTitle("Run LLM", for: .normal)
                runButton.addTarget(self, action: #selector(runLLM), for: .touchUpInside)
                runButton.frame = CGRect(x: 50, y: 100, width: 200, height: 50)
                view.addSubview(runButton)
        // Qwen configuration
//        let config = NimbleNetConfig(clientId: "testclient", clientSecret: "samplekey123", host: "https://apiv3.nimbleedge-staging.com", deviceId: "hello-ios", debug: true, compatibilityTag: "qwen3-executorch")
        
        // LLama Configuration
        let config = NimbleNetConfig(clientId: "chatapp-test", clientSecret: "samplekey123", host: "https://apiv3.nimbleedge-staging.com", deviceId: "hello-ios", debug: true, compatibilityTag: "EXECUTORCH", online: true)
        
        let res = NimbleNetApi.initialize(config: config)
        
        print("isInitialized? \(res)")
        let isReady = NimbleNetApi.isReady()
        print("isReady \(isReady)")
        while true {

            let modelStatus = NimbleNetApi.isReady()
            print(modelStatus)
            if modelStatus.status {
                break
            }
            Thread.sleep(forTimeInterval: 10)
        }

    }
    @objc func runLLM() {
        func callModel(prompt: String) -> String {
            let modelInputs: [String: NimbleNetTensor] = [
                "query": NimbleNetTensor(
                    data: prompt,
                    datatype: .string, shape: nil
                )
            ]
            let _ = NimbleNetApi.runMethod(methodName:"prompt_llm", inputs: modelInputs)
            Thread.sleep(forTimeInterval: 0.5)

            var finalOutputString = ""

            while true {
                let res = NimbleNetApi.runMethod(methodName: "get_next_str", inputs: [:])
                guard let outputData = res.payload else {
                            print("Error: No payload received")
                            break
                        }

                var outputMap: [String: NimbleNetTensor] = [:]
                for (key, tensorInternal) in outputData.map {
                    outputMap[key] = NimbleNetTensor(
                        data: tensorInternal.data,
                        datatype: tensorInternal.type,
                        shape: tensorInternal.shape
                    )
                }
                
                if outputMap["finished"] != nil {
                    break
                }
                
                if outputMap["str"] != nil {
                    let currentStr: String = outputMap["str"]?.data as? String ?? ""
                    if (!currentStr.isEmpty) {
                        finalOutputString += currentStr
                    }
                }

                Thread.sleep(forTimeInterval: 0.2)
            }

            print("First draft of story: \(finalOutputString)")
            return finalOutputString
        }
        
        for i in [0] {
            var contextArray = [Any]()

            var setContextInput: [String: NimbleNetTensor] = [
                "context": NimbleNetTensor(
                    data: contextArray,
                    datatype: .jsonArray, shape: [contextArray.count]
                )
            ]
            // _ = NimbleNetApi.runMethod(methodName:"clear_prompt", inputs: setContextInput)
          //  var result = NimbleNetApi.runMethod(methodName: "set_context", inputs: setContextInput)
            Thread.sleep(forTimeInterval: 0.5)
                //NSLog("Set context called")

            // 1st call
            var output = callModel(prompt: "Hello my name is Arpit and I am a big fan of Indian Cricket team.")
            print("CALL COMPLETED---")
            
            return
            
             var clearREs = NimbleNetApi.runMethod(methodName:"clear_prompt", inputs: setContextInput)
            print(clearREs)
            
            
            var output2 = callModel(prompt: "indian batters")
            print("CALL 2 COMPLETED---")
            
            _ = NimbleNetApi.runMethod(methodName:"clear_prompt", inputs: setContextInput)
            
            var output3 = callModel(prompt: "women cricket.")
            print("CALL COMPLETED---")
            
            _ = NimbleNetApi.runMethod(methodName:"clear_prompt", inputs: setContextInput)
            
            
            
            return
            contextArray.append(["type": "assistant", "message": output])
            contextArray.append(["type": "user", "message": "Hello my name is Arpit and I am a big fan of Indian Cricket team."])

            setContextInput = [
                "context": NimbleNetTensor(
                    data: contextArray,
                    datatype: .jsonArray, shape: [contextArray.count]
                )
            ]
           // _ = NimbleNetApi.runMethod(methodName:"set_context", inputs: setContextInput)

            // 2nd call
           // output = callModel(prompt: "Tell me about Indian cricket team.")

    //        _ = NimbleNetApi.runMethod(methodName:"clear_prompt", inputs: setContextInput)
            contextArray = []
            contextArray.append(["type": "assistant", "message": output])
            contextArray.append(["type": "user", "message": "Tell me about Indian cricket team."])

            setContextInput = [
                "context": NimbleNetTensor(
                    data: contextArray,
                    datatype: .jsonArray,
                    shape: [contextArray.count]
                )
            ]
           // _ = NimbleNetApi.runMethod(methodName: "set_context", inputs: setContextInput)

            // 3rd call
            output = callModel(prompt: "Can you tell me my name?")
            contextArray = []
            contextArray.append(["type": "assistant", "message": output])
            contextArray.append(["type": "user", "message": "Can you tell me my name?"])

            setContextInput = [
                "context": NimbleNetTensor(
                    data: contextArray,
                    datatype: .jsonArray,
                    shape: [contextArray.count]
                )
            ]
           // _ = NimbleNetApi.runMethod(methodName: "set_context", inputs: setContextInput)
            
            // 4th call
            output = callModel(prompt: "What do you know about me?")
        }
       
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

func delay(_ delay: Double, closure: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        closure()
    }
}

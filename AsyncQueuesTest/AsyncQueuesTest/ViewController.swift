//
//  ViewController.swift
//  AsyncQueuesTest
//
//  Created by lukas2 on 11.03.19.
//  Copyright © 2019 lukas2. All rights reserved.
//

import UIKit

class AlertOperation: AsynchronousOperation {
    
    weak var presentingViewController: UIViewController?
    let alertText: String
    
    init(presentingViewController viewController: UIViewController, alertText text: String) {
        presentingViewController = viewController
        alertText = text
    }
    
    override func execute() {
        // If you uncomment this then also uncomment queue.maxConcurrentOperationCount = 1 in ViewController.
//        print("Sleeping...")
//        sleep(1)
//        print("Waking up.")
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: self.alertText, message: "Press yes or no", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "YES", style: .default, handler: { [weak self] _ in
                self?.fakeDelegateMethod(result: true)
            }))
            
            alert.addAction(UIAlertAction(title: "NO", style: .default, handler: { [weak self] _ in
                self?.fakeDelegateMethod(result: false)
            }))
            
            self.presentingViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    func fakeDelegateMethod(result: Bool) {
        print("User selected {\(result ? "YES" : "NO")}")
        finish()
    }
}

class AfterAlertOperation: Operation {
    weak var presentingViewController: UIViewController?
    
    init(presentingViewController viewController: UIViewController) {
        presentingViewController = viewController
    }
    
    override func main() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Done", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.presentingViewController?.present(alert, animated: true, completion: nil)
        }
    }
}

class ViewController: UIViewController {

    private let queue = OperationQueue()
    
    @IBAction func tappedButton() {
        // Uncomment to make it serial, combine with sleep in AlertOperation's execute() to see the effect.
        // (Make sure you dismiss AfterAlertOperation's alert quickly enough. That operation does not block
        // anything and if the next Alert is to be shown, you will see an error that it cannot be presented
        // b/c the view controller is already presenting.)
        // queue.maxConcurrentOperationCount = 1
        
        let alertOperation = AlertOperation(presentingViewController: self, alertText: "This is a test.")
        let alertOperation2 = AlertOperation(presentingViewController: self, alertText: "One more time please!")
        let afterAlertOperation = AfterAlertOperation(presentingViewController: self)
        
        alertOperation2.addDependency(alertOperation)
        afterAlertOperation.addDependency(alertOperation2)
        
        // If i call tappedButton twice quickly, I will have enqueued 6 notifications. Dependencies mean that
        // only alertOperation (1) is ready to run, others wait. Will adding the second batch of 3 notifications
        // here certainly run AFTER the previous batch is through or can one of the operations from the second
        // batch interfere? (Perhaps need to explicitly .queuePriority on each operation?)
        queue.addOperations([alertOperation, alertOperation2, afterAlertOperation], waitUntilFinished: false)
    }
}

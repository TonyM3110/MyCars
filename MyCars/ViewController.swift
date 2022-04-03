//
//  ViewController.swift
//  MyCars
//
//  Created by Tony on 03.04.2022.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    let def = UserDefaults.standard
    
    var car: MyCars!
    
    var context: NSManagedObjectContext!
    lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .none
        return df
    }()
    
    @IBOutlet weak var segmentedControl: UISegmentedControl! {
        didSet {
            updateSegmentedControl()
            segmentedControl.selectedSegmentTintColor = .white
            let whiteTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            let blackTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            
            UISegmentedControl.appearance().setTitleTextAttributes(whiteTitleTextAttributes, for: .normal)
            UISegmentedControl.appearance().setTitleTextAttributes(blackTitleTextAttributes, for: .selected)
        }
    }
    
    @IBOutlet weak var markLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var carImageView: UIImageView!
    @IBOutlet weak var lastTimaStartedLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var myChoiceImageView: UIImageView!
    @IBOutlet weak var numberOfTrips: UILabel!
    
    
    @IBAction func segmantedControlPressed(_ sender: UISegmentedControl) {
        updateSegmentedControl()
       
    }
    
    
    @IBAction func startEnginePressed(_ sender: UIButton) {
        car.timesDriven += 1
        car.lastStarted = Date()
        
        do {
            try context.save()
            insertDataFrom(selectedCar: car)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    
    @IBAction func ratePressed(_ sender: UIButton) {
        let alert = UIAlertController(title: "Rated", message: "Rate this car", preferredStyle: .alert)
        let rateAction = UIAlertAction(title: "Rate", style: .default) { action in
            if let text = alert.textFields?.first?.text {
                self.update(rating: (text as NSString).doubleValue)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        alert.addTextField { textField in
            textField.keyboardType = .numberPad
        }
        alert.addAction(rateAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func update(rating: Double) {
        car.rating = rating
        
        do {
            try context.save()
            insertDataFrom(selectedCar: car)
        } catch let error as NSError {
            let alert = UIAlertController(title: "Wrong value", message: "Wrong Input", preferredStyle: .alert)
            let OkAction = UIAlertAction(title: "Ok", style: .default)
            
            alert.addAction(OkAction)
            present(alert, animated: true)
            print(error.localizedDescription)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if def.bool(forKey: "First")  {
            print("Not first launch.")
            def.set(true, forKey: "First")
        }
        else {
            print("first launch.")
            getDataFromFile()
            def.set(true, forKey: "First")
        }
        
    }
    
    private func updateSegmentedControl() {
        let fetchRequest: NSFetchRequest<MyCars> = MyCars.fetchRequest()
        let mark = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex)
        fetchRequest.predicate = NSPredicate(format: "mark == %@", mark!)
        
        do {
            let results = try context.fetch(fetchRequest)
            car = results.first
            insertDataFrom(selectedCar: car!)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    private func insertDataFrom(selectedCar car: MyCars) {
        carImageView.image = UIImage(data: car.imageData!)
        markLabel.text = car.mark
        modelLabel.text = car.model
        myChoiceImageView.isHidden = !(car.myChoice)
        ratingLabel.text = "Rating: \(car.rating) / 10"
        numberOfTrips.text = "Number of trips: \(car.timesDriven)"
        
        lastTimaStartedLabel.text = "Last time started: \(dateFormatter.string(from: car.lastStarted!))"
        segmentedControl.backgroundColor = car.tintColor as? UIColor
    }
    
    
    private func getDataFromFile() {
        
        let fetchRequest: NSFetchRequest<MyCars> = MyCars.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "mark != nil")
        
        var records = 0
        
        do {
            records = try context.count(for: fetchRequest)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        guard records == 0 else { return }
        
        guard let pathToFile = Bundle.main.path(forResource: "data", ofType: "plist"),
              let dataArray = NSArray(contentsOfFile: pathToFile) else { return }
        
        for dictionary in dataArray {
            let entity = NSEntityDescription.entity(forEntityName: "MyCars", in: context)
            let car = NSManagedObject(entity: entity!, insertInto: context) as! MyCars
            
            guard let carDictionary = dictionary as? [String : AnyObject] else { return }
            car.mark = carDictionary["mark"] as? String
            car.model = carDictionary["model"] as? String
            car.rating = carDictionary["rating"] as! Double
            car.lastStarted = carDictionary["lastStarted"] as? Date
            car.timesDriven = carDictionary["timesDriven"] as! Int16
            car.myChoice = carDictionary["myChoice"] as! Bool
            
            let imageName = carDictionary["imageName"] as? String
            let image = UIImage(named: imageName!)
            let imageData = image!.pngData()
            car.imageData = imageData
            
            if let colorDictionary = carDictionary["tintColor"] as? [String : Float] {
                car.tintColor = getColor(colorDictionary: colorDictionary)
                
            }
            
        }
        
    }
    private func getColor(colorDictionary: [String : Float]) -> UIColor {
        guard let red = colorDictionary["red"],
              let green = colorDictionary["green"],
              let blue = colorDictionary["blue"]
        else { return UIColor() }
        return UIColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: 1.0)
    }
}


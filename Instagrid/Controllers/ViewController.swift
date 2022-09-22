//
//  ViewController.swift
//  Instagrid
//
//  Created by edouard Kabia on 27/07/2022.
//

import UIKit
import PhotosUI

class ViewController: UIViewController {
    
    // MARK: - Picture Views outlet
    // top left button image we can hide it depending on desired display
    @IBOutlet weak var imvFirsToHide: UIButton!
    // top rigth button image
    @IBOutlet weak var imvSecond: UIButton!
    // bottom left button image we can hide it depending on desired display
    @IBOutlet weak var imvThirdToHide: UIButton!
    // bottom rigth button image
    @IBOutlet weak var imvFour: UIButton!
    // view for detecting swipe gesture
    @IBOutlet weak var pictureContainer: UIStackView!
    
    // MARK: - Additionnal view outlet
    // linked for changing text depending on orientation
    @IBOutlet weak var swipeUpLabel: UILabel!
    
    // MARK: - Display Views outlet
    // these button manage display, btnDisplayOne and btnDisplayTwo change actual display state
    @IBOutlet weak var btnDisplayOne: UIButton!
    // this button just show actual display state
    @IBOutlet weak var btnDisplayCenter: UIButton!
    //
    @IBOutlet weak var btnDisplayTwo: UIButton!
    
    // MARK: - Attributs
    // this if for storing the actual button pressed for gettting image, the returned image will be set as his image
    private var selectedImvButton : UIButton?
    // stored DisplayState struc tu get actual display
    private var actualState = DisplayState.HideBottom
    // array to store our differents style of display and witch button is associeted with ex : btnDisplayOne associated with display All , actually ...
    private var btnDisplayerArray : [BtnDisplayer] = [BtnDisplayer]()
    
    // MARK: - Override methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // initializing our required swipe gesture in our case it's UP for Portrait and Left for Landscape
        let UpSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe(_:)))
        UpSwipeGestureRecognizer.direction = .up
        //
        let leftSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe(_:)))
        leftSwipeGestureRecognizer.direction = .left
        // adding our gesture recognizer to our pictures parent view
        pictureContainer.addGestureRecognizer(UpSwipeGestureRecognizer)
        pictureContainer.addGestureRecognizer(leftSwipeGestureRecognizer)
        // before start lets know if we are able to pic picture in user photo library
        checkAuthorizationStatus()
        // lets inialize our btnDisplayer with defaut display
        InitDisplayer()
        // setting default display
        changeDisplay(selectedDisplay: nil)
        
    }
    
    // override viewWillTransition permit us to catch portrait and landscape change, with this we change our swipeUpLabel text to the correct sentence
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if(size.width > self.view.frame.size.width){ // landscape transition
            swipeUpLabel.text = "Swipe left to share"
        }
        else{ // portrait transition
            swipeUpLabel.text = "Swipe up to share"
        }
    }
    // Choosing image action
    
    // MARK: - Picture Views outlet actions
    /// Handle imvFirstToHidePressed pressed
    /// - Parameter sender: sender unUsed in our case
    @IBAction func imvFirstToHidePressed(_ sender: Any) {
        getPicture(actualBtn: imvFirsToHide)
    }
    
    /// Handle imvSecondPressed pressed
    /// - Parameter sender: sender unUsed in our case
    @IBAction func imvSecondPressed(_ sender: Any) {
        getPicture(actualBtn: imvSecond)
    }
    
    /// Handle imvThirdToHidePressed pressed
    /// - Parameter sender: sender unUsed in our case
    @IBAction func imvThirdToHidePressed(_ sender: Any) {
        getPicture(actualBtn: imvThirdToHide)
    }
    
    /// Handle imvFourPressed pressed
    /// - Parameter sender: sender unUsed in our case
    @IBAction func imvFourPressed(_ sender: Any) {
        getPicture(actualBtn: imvFour)
    }
    
    // MARK: - Display Views outlet actions
    /// Handle btnDisplayOne pressed
    /// - Parameter sender: sender unUsed in our case
    @IBAction func btnDisplayOnePressed(_ sender: Any) {
        changeDisplay(selectedDisplay: btnDisplayOne)
    }
    
    /// Handle btnDisplayTwoPressed pressed
    /// - Parameter sender: sender unUsed in our case
    @IBAction func btnDisplayTwoPressed(_ sender: Any) {
        changeDisplay(selectedDisplay: btnDisplayTwo)
    }
    
    // MARK: - Authorizations management
    
    /// function to take the user to the photo access settings in case of refusal or restriction of authorization
    private func showParam(){
        guard let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url)
        else {
            assertionFailure("Not able to open App privacy settings")
            return
        }
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Picture access", message: "The application requires access to your pictures in order to allow you to create and share your creations.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Setting", comment: "Default action"), style: .default, handler: { _ in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }))
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    /// Get the actual photo acces authorization status
    private func checkAuthorizationStatus(){
        let authorization_status : PHAuthorizationStatus
        
        if #available(iOS 14, *){
            authorization_status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        }
        else {
            authorization_status = PHPhotoLibrary.authorizationStatus()
        }
        manageRequestAuthorization(result: authorization_status)
    }
    
    /// Request photo acces authorization to user
    private func requestAuthorization(){
        if #available(iOS 14, *){
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { PHAuthorizationStatus in
                self.manageRequestAuthorization(result: PHAuthorizationStatus)
            }
        }
        else {
            PHPhotoLibrary.requestAuthorization { PHAuthorizationStatus in
                self.manageRequestAuthorization(result: PHAuthorizationStatus)
            }
        }
    }
    
    /// Manage result of checking actual or request photo acces authorization, by resquesting photo accces authorization if not determined or showing param if denied or restricted
    /// - Parameter result: result is type of PHAuthorizationStatus its returned when we ask for actual or request photo accces authorization
    private func manageRequestAuthorization(result : PHAuthorizationStatus){
        switch result {
            case .notDetermined:
            requestAuthorization()
                break
            case .denied , .restricted:
                showParam()
            case .authorized, .limited:
                break
            default :
                break
        }
    }
    
    // MARK: - Picture functionality
    
    /// able to choose a picture from user photo library if authorization is accorded, else show param to user
    /// - Parameter actualBtn: actualBtn type of UIButton, button to set the choosed image
    private func getPicture(actualBtn : UIButton){
        // authorization check
        let authorization_status : PHAuthorizationStatus
        //
        if #available(iOS 14, *){
            authorization_status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        }
        else {
            authorization_status = PHPhotoLibrary.authorizationStatus()
        }
        // result management
        switch authorization_status {
            case .notDetermined ,.restricted, .denied:
                showParam()
            case .authorized,.limited:
            // access granted, lets choose a picture
                DispatchQueue.main.async {
                    self.selectedImvButton = actualBtn
                    let vc = UIImagePickerController()
                    vc.sourceType = .photoLibrary
                    vc.delegate = self
                    vc.allowsEditing = true
                    self.present(vc, animated: true)
                }
            
            default :
                break
        }
    }
    
    /// Sharing creation by creating an image with pictureContainer, who's containing our 4 image assembled by display
    private func shareCreation(){
       
        if !checkCreationUnComplete(){
            let activityViewController = UIActivityViewController(activityItems: [pictureContainer.asImage()], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view
            // exclude some activity types from the list (optional)
            //activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook ]
            // present the view controller
            self.present(activityViewController, animated: true, completion: nil)
        }
        else{
            let alertVC = UIAlertController(title: "Erreur !", message: "Votre création n'est pas complete.", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(alertVC, animated: true, completion: nil)
        }
        
    }
    //
    /// Check all button in creation contains picture
    /// - Returns: return true if one of them doesn't and false if all of them contain de picture that is not default plus.
    private func checkCreationUnComplete()->Bool{
        var viewUncomplete = false
        switch actualState {
        case .HideTop:
            if let imvSecond = imvSecond.currentImage,
               let imvThree = imvThirdToHide.currentImage,
               let imvFour = imvFour.currentImage  {
                if imvSecond.description.contains("Plus") ||
                    imvThree.description.contains("Plus") ||
                    imvFour.description.contains("Plus"){
                    viewUncomplete = true
                }
                else {
                    viewUncomplete = false
                }
            }
        case .HideBottom:
            if let imvFirs = imvFirsToHide.currentImage,
               let imvSecond = imvSecond.currentImage,
               let imvFour = imvFour.currentImage  {
                if imvFirs.description.contains("Plus") ||
                    imvSecond.description.contains("Plus") ||
                    imvFour.description.contains("Plus"){
                    viewUncomplete = true
                }
                else {
                    viewUncomplete = false
                }
            }
        case .ShowAll:
            if let imvFirs = imvFirsToHide.currentImage,
               let imvSecond = imvSecond.currentImage,
               let imvThree = imvThirdToHide.currentImage,
               let imvFour = imvFour.currentImage  {
                if imvFirs.description.contains("Plus") ||
                    imvSecond.description.contains("Plus") ||
                    imvThree.description.contains("Plus") ||
                    imvFour.description.contains("Plus"){
                    viewUncomplete = true
                }
                else {
                    viewUncomplete = false
                }
            }
        }
        return viewUncomplete
    }
    /// function handler to handle our swipe events
    /// - Parameter sender: sender type of UISwipeGestureRecognizer but not user in our case
    @objc private func didSwipe(_ sender: UISwipeGestureRecognizer) {
        switch sender.direction {
            case .up:
                if UIApplication.shared.statusBarOrientation.isPortrait{
                    shareCreation()
                }
            case .left:
                if UIApplication.shared.statusBarOrientation.isLandscape{
                    shareCreation()
                }
            default:
                break
        }
    }
    
    // MARK: - Display functionality
    /// Manage display by showing default, and hide top or bottom and showwing all. Get pressed display button and switch old with selected display in btnDisplayerArray and apply it in view
    /// - Parameter selectedDisplay: selectedDisplay type of UIButton  witch is linked to a display state in our display array or any for default display
    private func changeDisplay(selectedDisplay : UIButton?) {
        // managing default and set
        if let selectedDisplay = selectedDisplay {
            // initialize old display state and new in btnDisplayerArray
            var selectedIndex = -1
            var oldIndex = -1
            // getting new selected btn linked with display state in array
            let selected = btnDisplayerArray.first { BtnDisplayer in
               BtnDisplayer.btn == selectedDisplay
            }
            // getting old selected btn linked with display state in array
            let oldSelected = btnDisplayerArray.first { BtnDisplayer in
               BtnDisplayer.btn == btnDisplayCenter
            }
            if let selected = selected{
                // getting state
                actualState = selected.displayState
                // retrive index of btn and display in btnDisplayerArray
                selectedIndex = btnDisplayerArray.firstIndex{$0.btn == selected.btn} ??  -1
               if let oldSelected = oldSelected {
                   // retrive index of old btn and display in btnDisplayerArray
                   oldIndex = btnDisplayerArray.firstIndex{$0.btn == oldSelected.btn} ??  -1
                   // retrive old imv et display state
                   let oldImv = oldSelected.btn.backgroundImage(for: .normal)
                   let oldState = oldSelected.displayState
                   // old display state switched with new by setting state and image of display to button
                   btnDisplayerArray[oldIndex].btn.setBackgroundImage(selected.btn.backgroundImage(for: .normal), for: .normal)
                   btnDisplayerArray[oldIndex].displayState = selected.displayState
                   // new selected get old imv and state
                   btnDisplayerArray[selectedIndex].btn.setBackgroundImage(oldImv, for: .normal)
                   btnDisplayerArray[selectedIndex].displayState = oldState
               }
            }
        }
        // apply actual selected state of display
        switch actualState {
        case .HideTop:
            imvFirsToHide.isHidden = true
            imvThirdToHide.isHidden = false
        case .HideBottom:
            imvThirdToHide.isHidden = true
            imvFirsToHide.isHidden = false
        case .ShowAll:
            imvFirsToHide.isHidden = false
            imvThirdToHide.isHidden = false
        }
        
    }
    //
    /// Link our display state with button in default
    private func InitDisplayer(){
        btnDisplayerArray.append(BtnDisplayer(btn: btnDisplayOne, displayState: .HideTop))
        btnDisplayerArray.append(BtnDisplayer(btn: btnDisplayCenter, displayState: .HideBottom))
        btnDisplayerArray.append(BtnDisplayer(btn: btnDisplayTwo,  displayState: .ShowAll))
    }
    // MARK: -
}


extension ViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //
    /// Extention to handle Image picking from user photo library
    /// - Parameters:
    ///   - picker: picker UIImagePickerController unused in our state
    ///   - info: info used to get choosed image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerEditedImage")] as? UIImage{
            if let imv = selectedImvButton {
                imv.setImage(image, for: .normal)
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }
    //
    /// Dismiss image picker after operation
    /// - Parameter picker: picker to dismiss
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension UIView {
    

    // Using a function since `var image` might conflict with an existing variable
    // (like on `UIImageView`)
    /// Capture view to make image from it
    /// - Returns: return UIImage from ou view by capture
    func asImage() -> UIImage {
        if #available(iOS 10.0, *) {
            let renderer = UIGraphicsImageRenderer(bounds: bounds)
            return renderer.image { rendererContext in
                layer.render(in: rendererContext.cgContext)
            }
        } else {
            UIGraphicsBeginImageContext(self.frame.size)
            self.layer.render(in:UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return UIImage(cgImage: image!.cgImage!)
        }
    }
}


//
/// Our differents Display
enum DisplayState{
    case HideTop,HideBottom,ShowAll
}
//
/// Link of button and Display state
struct BtnDisplayer {
    var btn : UIButton
    var displayState : DisplayState
}

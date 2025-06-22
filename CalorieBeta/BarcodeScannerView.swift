import SwiftUI
import FirebaseFirestore
import AVFoundation

// This view provides a barcode scanner interface using AVFoundation, allowing users to scan
// food barcodes and fetch corresponding food items from the FatSecret API.
struct BarcodeScannerView: UIViewControllerRepresentable {
    // Environment variable to control dismissal of the view.
    @Environment(\.presentationMode) var presentationMode
    // Closure to pass the detected food item back to the parent view.
    var onFoodItemDetected: (FoodItem) -> Void

    // Instance of the FatSecret API service to fetch food data.
    private let fatSecretService = FatSecretFoodAPIService()

    // Creates a coordinator to handle AVCaptureMetadataOutputDelegate callbacks.
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self) // Returns a new Coordinator instance.
    }

    // Creates and configures the UIViewController for the scanner.
    func makeUIViewController(context: Context) -> ScannerViewController {
        let viewController = ScannerViewController() // Initializes the scanner view controller.
        viewController.delegate = context.coordinator // Sets the coordinator as the delegate.
        return viewController
    }

    // Updates the UIViewController when the SwiftUI view changes (currently no updates needed).
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    // Coordinator class to handle barcode detection and API calls.
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: BarcodeScannerView // Reference to the parent view.

        init(parent: BarcodeScannerView) {
            self.parent = parent // Initializes with the parent view.
        }

        // Called when metadata (e.g., barcodes) is detected by the camera.
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first, // Gets the first detected object.
               let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
               let barcode = readableObject.stringValue { // Extracts the barcode string.

                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate)) // Vibrates the device.

                DispatchQueue.main.async { [weak self] in // Ensures UI updates on the main thread.
                    guard let self = self else { return } // Prevents retain cycles with weak self.
                    self.parent.presentationMode.wrappedValue.dismiss() // Dismisses the scanner view.
                    self.fetchFromFatSecret(barcode: barcode) // Fetches food data for the barcode.
                }
            }
        }

        // Fetches food details from FatSecret using the detected barcode.
        private func fetchFromFatSecret(barcode: String) {
            parent.fatSecretService.fetchFoodByBarcode(barcode: barcode) { result in
                DispatchQueue.main.async { // Ensures UI updates on the main thread.
                    switch result {
                    case .success(let foodItems):
                        if let firstFoodItem = foodItems.first { // Uses the first matching food item.
                            print("✅ Navigating to FoodDetailView for: \(firstFoodItem.name)") // Logs success.
                            self.parent.onFoodItemDetected(firstFoodItem) // Passes the food item to the parent.
                        } else {
                            print("⚠️ No valid results found.") // Logs when no food is found.
                        }
                    case .failure(let error):
                        print("❌ No results found. Error: \(error.localizedDescription)") // Logs any errors.
                    }
                }
            }
        }
    }
}

// ✅ **Restored `ScannerViewController` to fix "Cannot find in scope" errors**
// Custom UIViewController to manage the camera and barcode scanning process.
class ScannerViewController: UIViewController {
    var captureSession: AVCaptureSession? // Manages the camera input and output.
    var previewLayer: AVCaptureVideoPreviewLayer! // Displays the camera feed.
    var delegate: AVCaptureMetadataOutputObjectsDelegate? // Delegate for metadata detection.

    override func viewDidLoad() {
        super.viewDidLoad() // Calls the superclass's view setup.
        setupCamera() // Initializes the camera.
        setupOverlay() // Adds a visual overlay for scanning guidance.
    }

    // Sets up the camera session and configures input/output.
    func setupCamera() {
        captureSession = AVCaptureSession() // Initializes the capture session.

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return } // Gets the default video device.
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice) // Creates input from the device.
            if captureSession?.canAddInput(videoInput) == true {
                captureSession?.addInput(videoInput) // Adds the input if supported.
            }
        } catch {
            return // Exits if input setup fails.
        }

        let metadataOutput = AVCaptureMetadataOutput() // Creates metadata output for barcode detection.
        if captureSession?.canAddOutput(metadataOutput) == true {
            captureSession?.addOutput(metadataOutput) // Adds the output if supported.
            metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main) // Sets delegate and main queue.
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .qr] // Specifies supported barcode types.
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!) // Creates the preview layer.
        previewLayer.frame = view.layer.bounds // Matches the layer to the view bounds.
        previewLayer.videoGravity = .resizeAspectFill // Fills the view while maintaining aspect ratio.
        view.layer.addSublayer(previewLayer) // Adds the preview layer to the view.

        DispatchQueue.global(qos: .background).async { // Runs camera start on a background thread.
            self.captureSession?.startRunning() // Starts the capture session.
        }
    }

    // Adds a green-bordered overlay to guide the user during scanning.
    func setupOverlay() {
        let overlayView = UIView() // Creates a new view for the overlay.
        overlayView.layer.borderColor = UIColor.green.cgColor // Sets a green border.
        overlayView.layer.borderWidth = 3 // Sets border width.
        overlayView.backgroundColor = UIColor.clear // Transparent background.
        overlayView.translatesAutoresizingMaskIntoConstraints = false // Enables Auto Layout.
        view.addSubview(overlayView) // Adds the overlay to the view.

        // Sets up constraints for the overlay.
        NSLayoutConstraint.activate([
            overlayView.centerXAnchor.constraint(equalTo: view.centerXAnchor), // Centers horizontally.
            overlayView.centerYAnchor.constraint(equalTo: view.centerYAnchor), // Centers vertically.
            overlayView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6), // 60% of view width.
            overlayView.heightAnchor.constraint(equalTo: overlayView.widthAnchor, multiplier: 0.5) // Height 50% of width.
        ])
    }
}

use hidapi::HidApi;

// Not hardware access: initialises the hidapi library and lists HID devices, but opens no
// device and sends nothing. Asserts that devices will be opened shared, not seized.
#[test]
fn macos_hidapi_opens_devices_non_exclusively() {
    let api = HidApi::new().expect("hidapi init");
    assert!(
        !api.get_open_exclusive(),
        "hidapi would seize the MV7 on macOS; enable the macos-shared-device feature"
    );
}

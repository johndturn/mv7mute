use super::support::{FakeTransport, run_scripted};
use crate::mv7::Mv7;
use crate::{
    Command, query_state_with_mv7, run, run_with_mv7, toggle_lock_state_with_mv7,
    toggle_mute_state_with_mv7,
};

#[test]
fn toggle_restores_lock_when_device_started_locked() {
    let (result, state) = run_scripted(
        Command::Toggle,
        vec![
            Ok(Some("su=adm")),
            Ok(Some("lock=on")),
            Ok(Some("micMute=off")),
        ],
    );

    assert_eq!(result.unwrap(), vec!["muted"]);
    assert_eq!(
        *state.sent.borrow(),
        vec![
            "su adm",
            "lock",
            "lock off",
            "micMute",
            "micMute on",
            "lock on"
        ]
    );
}

#[test]
fn toggle_does_not_relock_when_device_started_unlocked() {
    let (result, state) = run_scripted(
        Command::Toggle,
        vec![
            Ok(Some("su=adm")),
            Ok(Some("lock=off")),
            Ok(Some("micMute=off")),
        ],
    );

    assert_eq!(result.unwrap(), vec!["muted"]);
    assert_eq!(
        *state.sent.borrow(),
        vec!["su adm", "lock", "micMute", "micMute on"]
    );
}

#[test]
fn unlock_leaves_device_unlocked() {
    let (result, state) = run_scripted(
        Command::Unlock,
        vec![Ok(Some("su=adm")), Ok(Some("lock=on"))],
    );

    assert_eq!(result.unwrap(), vec!["unlocked"]);
    assert_eq!(
        *state.sent.borrow(),
        vec!["su adm", "lock", "lock off", "lock off"]
    );
}

#[test]
fn lock_leaves_device_locked_without_extra_restore() {
    let (result, state) =
        run_scripted(Command::Lock, vec![Ok(Some("su=adm")), Ok(Some("lock=on"))]);

    assert_eq!(result.unwrap(), vec!["locked"]);
    assert_eq!(
        *state.sent.borrow(),
        vec!["su adm", "lock", "lock off", "lock on"]
    );
}

#[test]
fn status_restores_lock_and_reports_original_state() {
    let (result, state) = run_scripted(
        Command::Status,
        vec![
            Ok(Some("su=adm")),
            Ok(Some("lock=on")),
            Ok(Some("micMute=on")),
        ],
    );

    assert_eq!(result.unwrap(), vec!["muted", "locked"]);
    assert_eq!(
        state.sent.borrow().last().map(String::as_str),
        Some("lock on")
    );
}

#[test]
fn init_authenticates_then_queries_lock_only() {
    let (transport, state) =
        FakeTransport::scripted(vec![Ok(Some("su=adm")), Ok(Some("lock=off"))]);
    let mut mv7 = Mv7::new(transport);

    mv7.init().unwrap();

    assert_eq!(*state.sent.borrow(), vec!["su adm", "lock"]);
}

/// The only commands this fork may send to the device (AGENTS.md, "Hardware safety").
/// Anything else, including `bootDSP`, needs the maintainer's approval first.
const ALLOWED_COMMANDS: [&str; 7] = [
    "su adm",
    "lock",
    "lock on",
    "lock off",
    "micMute",
    "micMute on",
    "micMute off",
];

#[test]
fn every_path_sends_only_allowlisted_commands() {
    type Path = fn(&mut Mv7<FakeTransport>) -> Result<(), String>;
    let paths: [(&str, Path); 9] = [
        ("run Toggle", |m| run_with_mv7(m, Command::Toggle).map(drop)),
        ("run On", |m| run_with_mv7(m, Command::On).map(drop)),
        ("run Off", |m| run_with_mv7(m, Command::Off).map(drop)),
        ("run Status", |m| run_with_mv7(m, Command::Status).map(drop)),
        ("run Lock", |m| run_with_mv7(m, Command::Lock).map(drop)),
        ("run Unlock", |m| run_with_mv7(m, Command::Unlock).map(drop)),
        ("query_state", |m| query_state_with_mv7(m).map(drop)),
        ("toggle_mute_state", |m| {
            toggle_mute_state_with_mv7(m).map(drop)
        }),
        ("toggle_lock_state", |m| {
            toggle_lock_state_with_mv7(m).map(drop)
        }),
    ];

    for initial_lock in ["lock=on", "lock=off"] {
        for (name, path) in paths {
            let (transport, state) = FakeTransport::scripted(vec![
                Ok(Some("su=adm")),
                Ok(Some(initial_lock)),
                Ok(Some("micMute=off")),
            ]);
            let mut mv7 = Mv7::new(transport);

            let result = path(&mut mv7);
            drop(mv7);

            assert!(result.is_ok(), "{name} ({initial_lock}) failed: {result:?}");
            let sent = state.sent.borrow();
            for cmd in sent.iter() {
                assert!(
                    ALLOWED_COMMANDS.contains(&cmd.as_str()),
                    "{name} ({initial_lock}) sent non-allowlisted {cmd:?}: {sent:?}"
                );
            }
        }
    }
}

#[test]
fn version_returns_package_version_without_device_io() {
    let result = run(Command::Version);

    assert_eq!(
        result.unwrap(),
        vec![format!("mv7mute {}", env!("CARGO_PKG_VERSION"))]
    );
}

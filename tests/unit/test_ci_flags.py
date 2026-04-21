from __future__ import annotations

from scripts.ci_flags import resolve_flags


def test_ci_flag_resolution_matrix() -> None:
    cases = [
        ("push", "refs/heads/main", "", "", True, True),
        ("push", "refs/heads/feature", "", "", False, False),
        ("pull_request", "refs/pull/1/merge", "", "", True, False),
        ("workflow_dispatch", "refs/heads/main", "true", "true", True, True),
        ("workflow_dispatch", "refs/heads/main", "1", "1", True, True),
        ("workflow_dispatch", "refs/heads/main", "false", "true", True, True),
        ("workflow_dispatch", "refs/heads/main", "", "false", False, False),
        ("workflow_dispatch", "refs/heads/main", "true", "", True, False),
        ("workflow_dispatch", "refs/heads/feature", "true", "true", False, False),
    ]

    for (
        event_name,
        ref,
        test_input,
        publish_input,
        expected_test,
        expected_publish,
    ) in cases:
        result = resolve_flags(
            event_name=event_name,
            ref=ref,
            run_tests_input=test_input,
            publish_images_input=publish_input,
        )
        assert result.run_tests_requested is expected_test
        assert result.publish_requested is expected_publish

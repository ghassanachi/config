/* INFO */

setHandler('i', HYPER, () => {
    const windows = Space.active().windows();
    const sFrame = Screen.main().flippedFrame();

    windows.forEach((window) => {
        if (!window.isVisible() || !window.title()) {
            return;
        }

        const wFrame = window.frame();
        const app = window.app();

        Modal.build({
            origin: function(mFrame) {
                return {
                    x: wFrame.x + wFrame.width / 2 - mFrame.width / 2,
                    y: sFrame.height - (wFrame.y + wFrame.height / 2 + mFrame.height / 2),
                };
            },
            weight: ALERT_WEIGHT,
            duration: ALERT_DURATION,
            animationDuration: ALERT_ANIMATION_DURATION,
            appearance: ALERT_APPEARANCE,
            icon: app.icon(),
        }).show();
    });
});

/* SET EVENTS HANDLER */

function setEventsHandler(events, handler) {
    events.forEach((event) => {
        return setEventHandler(event, handler);
    });
}

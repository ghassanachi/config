/* SPACES */

setHandler('tab', HYPER, () => {
    return switchSpace(1);
});

setHandler('tab', HYPER_SHIFT, () => {
    return switchSpace(-1);
});

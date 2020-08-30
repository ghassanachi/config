/* GROW */

const grow = [
    [ 'k', HYPER_SHIFT, [ 0, -GROW_AMOUNT, 0, GROW_AMOUNT ] ],
    [ 'l', HYPER_SHIFT, [ 0, 0, GROW_AMOUNT, 0 ] ],
    [ 'j', HYPER_SHIFT, [ 0, 0, 0, GROW_AMOUNT ] ],
    [ 'h', HYPER_SHIFT, [ -GROW_AMOUNT, 0, GROW_AMOUNT, 0 ] ],
];

setHandlers(growFrame, grow, false);

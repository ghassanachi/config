/* GET SPACE INDEX */

function getSpaceIndex(space = Space.active()) {
    return Space.all().findIndex((s) => {
        return s.isEqual(space);
    });
}

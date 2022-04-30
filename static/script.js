
function redirect_to(step_num) {
    const dict = {
        1: '/convert_db',
        2: '/',
        3: '/all',
    }
    if ([1].includes(step_num)) {
        location.href = dict[step_num];
    } else if ([2].includes(step_num)) {
        const input_step_2_1 = document.getElementById('step_' + step_num + '_1').value;
        location.href = dict[step_num] + input_step_2_1;
    } else if ([3].includes(step_num)) {
        location.href = dict[step_num];
    }
}

function showHide() {
	if (document.getElementById('content-1-show')) {
		if (document.getElementById('content-1-show').className = 'content-1-show') {
			document.getElementById('content-1-show').className = 'content-1-show_visible';
		}
	}
}

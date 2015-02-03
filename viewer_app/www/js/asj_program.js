//var now = new Date();
var current_day  = 1;
var current_room = 1;
//var now = new Date(2014, 9-1, 3, 13, 00, 0);
var now = new Date();

function update_now(append_minutes) {
	if (append_minutes <= -1440) {
		now = new Date(2014, 9-1, 3, 8, 30, 0);
	}
	else if(append_minutes) {
		now = new Date(now.getTime() + append_minutes*60*1000);
	}
	else {
		now = new Date();
	}
//	now = new Date(now.getTime() + 5*60*1000);
	
	//console.log("Now = " + now);
}

var asjp_refresh_timer;
function asjp_update_now(append_minutes) {
	update_now(append_minutes);
	if(append_minutes) {
		if(asjp_refresh_timer) {
			clearInterval(asjp_refresh_timer);
			asjp_refresh_timer = undefined;
		}
		return true;
	}

	if(!asjp_refresh_timer) {
		asjp_refresh_timer = setInterval(function(){
			update_now();
				asjp_update_now();
				asjp_updatehtml_nowtime();
			}, 1*1000);
	}
	return true;
}

var _asjp_updatehtml_nowtime_count = 0;
function asjp_updatehtml_nowtime() {
	var h_str = "" + now.getHours(),
		m_str = "" + now.getMinutes(),
		s_str = "" + now.getSeconds();
	if(now.getHours() < 10) h_str = "0"+h_str;
	if(now.getMinutes() < 10) m_str = "0"+m_str;
	if(now.getSeconds() < 10) s_str = "0"+s_str;
	
	if(!asjp_refresh_timer || ++_asjp_updatehtml_nowtime_count % 2 == 0)
		$("#nowtime").html(h_str+":"+m_str);
	else
		$("#nowtime").html(h_str+" "+m_str);
}

function asjp_select_day(day) {
	var i;
	for(i=1; i<=3; ++i) {
		if(day == i) {
			$("li#day"+i).addClass("active");
		} else {
			$("li#day"+i).removeClass("active");
		}
	}
	asjp_initialize_panels(day);
}

function asjp_initialize_panels(_current_day) {
	current_day = _current_day;
	asjp_updatehtml_panels();
}

function _asjp_html_session_header(theme, room_num, pid) {
	var newurl = "detail.html#" + pid;
	return '<span class="theme"><a style="color:black;" href="'+newurl+'">' + theme
		+ '<span class="visible-xs-inline"> &raquo;</span>'
		+ '</a></span>'
		+ ' <a class="btn btn-default btn-xs hidden-xs" href="'+newurl+'" role="button">Details &raquo;</a>'
//	return '<p class="theme">' + theme + '</p>'
//	     + '<p><a class="btn btn-default btn-xs hidden-xs" href="'+newurl+'" role="button">Details &raquo;</a></p>';

}

function _asjp_html_postersession_header(theme, room_num, pid) {
	var newurl = "detail.html#" + current_day + "-" + room_num + "-" + pid;
	return '<span class="theme"><a style="color:black;" href="'+newurl+'">' + theme
		+ '<span class="visible-xs-inline"> &raquo;</span>'
		+ '</a></span>'
		+ ' <a class="btn btn-default btn-xs hidden-xs" href="'+newurl+'" role="button">Details &raquo;</a>'
}

function _asjp_updatehtml_postersession_body(target_elem, place_obj, room_num) {
	var session_num = 0;
	for(session_num=0; session_num<place_obj.sessions.length; ++session_num) {
		var cur_session = place_obj.sessions[session_num];

		var cur_presen = get_current_presentation(cur_session, now);
		if(cur_presen != null) {
			newhtml  = '<p class="session_header ellipsis">';
			newhtml += _asjp_html_postersession_header(cur_session.theme, room_num, cur_session.data[0].id);
			newhtml += '</p>';
			target_elem.append(newhtml);
			
			newhtml  = '<p class="presen cur_presen ellipsis">';
			newhtml += get_poster_html(cur_presen);
			newhtml += '</p>';

			target_elem.append(newhtml);
		}

		var next_presen = get_next_presentation(cur_session, now);
		if(next_presen != null) {
			if(cur_presen == null ) {
				newhtml  = '<p class="session_header ellipsis">';
				newhtml += _asjp_html_postersession_header(cur_session.theme, room_num, cur_session.data[0].id);
				newhtml += '</p>';
				target_elem.append(newhtml);
			}

			newhtml = '<p class="presen next_presen ellipsis">';
			newhtml += get_poster_html(next_presen);
			newhtml += '</p>';

			target_elem.append(newhtml);

			break;
		}

		// if(cur_presen != null || next_presen != null) break;
	}
}

function _asjp_updatehtml_session_body(target_elem, place_obj, room_num) {
	var session_num = 0;
	for(session_num=0; session_num<place_obj.sessions.length; ++session_num) {
		var cur_session = place_obj.sessions[session_num];

		//console.log(cur_session);

		var cur_presen = get_current_presentation(cur_session, now);
		if(cur_presen != null) {
			newhtml  = '<p class="session_header">';
			newhtml += _asjp_html_session_header(cur_session.theme, room_num, cur_session.data[0].id);
			newhtml += '</p>';
			target_elem.append(newhtml);
			
			newhtml  = '<p class="presen cur_presen ellipsis">';
			newhtml += get_presentation_html(cur_presen);
			newhtml += '</p>';

			target_elem.append(newhtml);

		}

		var next_presen = get_next_presentation(cur_session, now);
		if(next_presen != null) {
			if(cur_presen == null ) {
				newhtml  = '<p class="session_header">';
				newhtml += _asjp_html_session_header(cur_session.theme, room_num, cur_session.data[0].id);
				newhtml += '</p>';
				target_elem.append(newhtml);
			}

			newhtml = '<p class="presen next_presen ellipsis">';
			newhtml += get_presentation_html(next_presen);
			newhtml += '</p>';

			target_elem.append(newhtml);

			break;
		}

		// if(cur_presen != null || next_presen != null) break;
	}

}

function asjp_updatehtml_panels() {
	var i;
	
	// For oral presentaions
	for(var place_num = 0; place_num<10; ++place_num) {
		var place_obj = json[current_day-1][place_num];

		var target_elem = $("div#place"+(place_num+1)+"body");

		if(!place_obj.sessions) {
			var newhtml = "";
			newhtml  = '<p class="theme">CLOSED</p>';
			
			target_elem.html(newhtml);

			continue;
		}
		
		target_elem.html("");
		//console.log(place_obj);
		_asjp_updatehtml_session_body(target_elem, place_obj, place_num+1);
	}
	
	// For poster presentations
	for(var place_num = 10; place_num<14; ++place_num) {
		var place_obj = json[current_day-1][place_num];

		var target_elem = $("div#place"+(place_num+1)+"body");

		if(!place_obj.sessions) {
			var newhtml = "";
			newhtml  = '<p class="theme">CLOSED</p>';
			
			target_elem.html(newhtml);

			continue;
		}
		
		target_elem.html("");
		_asjp_updatehtml_postersession_body(target_elem, place_obj, place_num+1);
	}

	// Add events
	$(".ellipsis").click( function() {
		console.log("a");
		$(this).toggleClass("ellipsis");
	});

	if($(window).width() > 500) {
		$(".ellipsis").toggleClass("ellipsis", false); 
	}
}

function get_presentation_html(cur_data) {
	return '<span class="presen_id">' + cur_data.id + '</span> '
	     + '<span class="presen_time">(' + cur_data.start + ' ～ ' + cur_data.end   + ')</span><br/>'
	     + '<span class="presen_title"><b>' + cur_data.title + '</b></span><br/>'
	     + '<span class="presen_authors"><small>' + cur_data.authors + '</small></span>';
}

function get_poster_html (cur_data) {
	return '<span class="presen_time">(' + cur_data.start + ' ～ ' + cur_data.end   + ')</span>';
}

function get_next_presentation(session, now) {
	var i;
	var now_val = now.getHours() * 100 + now.getMinutes() * 1;

	for(i=0; i<session.data.length; ++i) {
		var start_val = timestr2val(session.data[i].start);
		if (now_val < start_val) return session.data[i];
	}

	return null;
}

function get_current_presentation(session, now) {
	var i;
	var now_val = now.getHours() * 100 + now.getMinutes() * 1;

	for(i=0; i<session.data.length; ++i) {
		var end_val = timestr2val(session.data[i].end);
		if (end_val <= now_val) continue;

		var start_val = timestr2val(session.data[i].start);
		if(start_val <= now_val)
			return session.data[i];
		else
			break;
	}

	return null;
}

function timestr2val(time_str) {
	return time_str.substr(0,2) * 100 + time_str.substr(3,2)*1;

}

function asjd_updatehtml_current_session () {
  var place_obj = json[current_day-1][current_room-1];

  $(".session_detail").removeClass("cur_presen");
  $(".session_detail").removeClass("next_presen");

  for(var i=0; i<place_obj.sessions.length; ++i) {
    var session_num = i;
    var cur_session = place_obj.sessions[session_num];

    var cur_presen = get_current_presentation(cur_session, now);
    if(cur_presen != null) {
      var id = cur_presen.id;
      $("#"+cur_presen.id).addClass("cur_presen");
    }

    var next_presen = get_next_presentation(cur_session, now);
    if(next_presen != null) {
      var id = next_presen.id;
      $("#"+next_presen.id).addClass("next_presen");

      break;
    }

  }

}

function asjd_initialize_view () {
  var place_obj = json[current_day-1][current_room-1];

  console.log("day = " + current_day + " / room = " + current_room);
  
  $("#asjd_detail_content").html( tmpl_asjd_detail_content.render(place_obj) );

  asjd_updatehtml_current_session();
}

function asjd_select_room (active_room, need_render) {
	var i;
	
	acrive_room = parseInt(active_room);

	if(active_room < 1) return false;
	if(active_room > 14) return false;

	for(i=1; i<=14; ++i) {
		if(active_room == i) {
			$("#btn_"+i).addClass("active");
		} else {
			$("#btn_"+i).removeClass("active");
		}
	}
	current_room = active_room;
	if(need_render != false)
	asjd_initialize_view();

	return true;
}

function asjd_select_day (active_day, need_render) {
	var i;
	for(i=1; i<=3; ++i) {
		if(active_day == i) {
			$("#day"+i).addClass("active");
		} else {
			$("#day"+i).removeClass("active");
		}
	}
  current_day = active_day;
  if(need_render != false)
	  asjd_initialize_view(active_day, current_room);
}

/**
 * parse "#\d" and "#\d-\d+"
 */
function parse_day_and_room (url) {
  var day  = 1,
      room = 1,
      pnum = 1;
  var pid = '';

  if(!url) {
    url = window.location.href;
  }

  console.log(url);
  var elm = $('<a>', { href: url } )[0];
  var q = elm.hash.substr(1).split('-');
  if(elm.hash && q.length >= 1) {
    day = parseInt(q[0]);
  }
  if(q.length >= 2) {
    room = parseInt(q[1]);
  }
  if(q.length >= 3) {
    pnum = parseInt(q[2]);
  }
  if(q.length >= 5) {
    pid = '' + q[2] + '-' + q[3] + '-' + q[4];
  } else {
    pid = '' + day + '-' + room + '-' + pnum;
  }
  return {day: day, room: room, pnum: pnum, pid: pid};
}

/**
 * Zoom in/out (font-size)
 */
var current_font_size = 14;
function zoom_font_size (elem_id, zoom) {
	var elem = $(elem_id);
	current_font_size += zoom;
	elem.css("font-size", current_font_size+"px");
}

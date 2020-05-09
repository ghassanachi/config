function fish_greeting -d "Greeting message on shell session start up"

    echo ""
    echo -en "        |         " (welcome_message) "\n"
    echo -en "       / \        \n"
    echo -en "      / _ \       " (show_date_info) "\n"
    echo -en "     |.o '.|      \n"
    echo -en "     |'._.'|      \n"
    echo -en "     |     |	\n" 
    echo -en "   ,'|  |  |`.   	\n" 
    echo -en "  /  |  |  |  \ 	\n" 
    echo -en "  |,-'--|--'-.| 	\n" 
    echo ""
    set_color grey
    echo "Have a nice trip"
    set_color normal
end


function welcome_message -d "Say welcome to user"

    echo -en "Welcome aboard captain "
    set_color FFF  # white
    echo -en (whoami) "!"
    set_color normal
end


function show_date_info -d "Prints information about date"

    set --local up_time (uptime | cut -d "," -f1 | cut -d "p" -f2 | sed 's/^ *//g')

    set --local time (echo $up_time | cut -d " " -f2)
    set --local formatted_uptime $time

    switch $time
    case "days" "day"
        set formatted_uptime "$up_time"
    case "min"
        set formatted_uptime $up_time"utes"
    case '*'
        set formatted_uptime "$formatted_uptime hours"
    end

    echo -en "Today is "
    set_color cyan
    echo -en (date +%Y.%m.%d)
    set_color normal
    echo -en ", we are up and running for "
    set_color cyan
    echo -en "$formatted_uptime"
    set_color normal
    echo -en "."
end


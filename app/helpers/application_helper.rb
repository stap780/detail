module ApplicationHelper

    def flash_class(level)
        case level
        when "info" then "alert alert-info"
        when "notice", "success" then "alert alert-success"
        when "error" then "alert alert-danger"
        when "alert" then "alert alert-warning"
        end
    end
    

    def prepend_flash
        turbo_stream.prepend "our_flash", partial: "shared/flash"
    end

    def div_check_box_tag_all
        content_tag :div, class: "col-1 d-flex self-content-start" do
            check_box_tag("selectAll", "selectAll", class: "checkboxes form-check-input", data: {selectall_target: "checkboxAll", action: "change->selectall#toggleChildren"})
        end
    end


    def caret_left_icon
        '<i class="bi bi-caret-left"></i>'.html_safe
    end

    def search_icon
        '<i class="bi bi-search"></i></span>'.html_safe
    end

    def eye_fill_icon
        '<i class="bi bi-eye-fill"></i>'.html_safe
    end

    def arrow_right_icon
        '<i class="bi bi-arrow-right"></i>'.html_safe
    end

    def list_icon
        '<i class="bi bi-list"></i>'.html_safe
    end

    def arrow_clockwise_icon
        "<i class='bi bi-arrow-clockwise'></i>".html_safe
    end

    def box_arrow_up_right_icon
        '<i class="bi bi-box-arrow-up-right"></i>'.html_safe
    end

    def sidekiq_icon
        '<i class="bi bi-app"></i>'.html_safe
    end
        
    def close_icon
        '<i class="bi bi-x"></i>'.html_safe
    end

    def false_icon
        '<i class="bi bi-x-circle"></i>'.html_safe
    end

    def more_icon
        '<i class="bi bi-three-dots"></i>'.html_safe
      end
    
    def download_icon
    '<i class="bi bi-cloud-arrow-down"></i>'.html_safe
    end

    def add_icon
    "<i class='bi bi-plus'></i> #{t("add")}".html_safe
    end

    def play_icon
    '<i class="bi bi-play"></i>'.html_safe
    end

    def edit_icon
    '<i class="bi bi-pencil"></i>'.html_safe
    end

    def trash_icon
    '<i class="bi bi-trash3"></i>'.html_safe
    end

    def check2_icon
        '<i class="bi bi-check2"></i>'.html_safe
    end


    def li_menu_link_to(name = nil, options = nil, html_options = nil, &block)
        status = current_page?(options) ? "active" : ""
        content_tag :li, class: "nav-item #{status}" do
          link_to(name, options, html_options, &block)
        end
    end



end

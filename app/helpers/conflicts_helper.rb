module ConflictsHelper
  def arec name, address, style="", extra=nil; rec name, address, "Address(A) record", "arec", style, extra; end
  def prec address, name, style="", extra=nil; rec address, name, "Reverse(PTR) record","prec", style, extra; end

  def dns_host_entry host, collision
    content_tag(:td, :colspan => 2) do
      content_tag(:fieldset) do
        content_tag(:legend, "Host's DNS registration") +
        arec(host.name, host.ip, "float:left;",  "DNS A record #{collision.dns_name_missing ? "missing" : "present"}") +
        prec(host.ip, host.name, "float:right;", "DNS PTR record #{collision.dns_ip_missing ? "missing" : "present"}")
      end
    end
  end

  def dns_collision_entries host, collision
    content_tag(:td, dns_ip_collision(host, collision)) +
    content_tag(:td, dns_name_collision(host, collision))
  end

  def dns_ip_collision host, collision
    owner = collision.dns_ip_owner
    content_tag(:fieldset) do
      legend("dns_ip", collision.dns_ip_entry) +
      prec(host.ip, collision.dns_ip_entry) +
      arec(collision.dns_ip_entry, collision.dns_ip_secondary_entry) +
      "Foreman owner: #{owner}"
    end
  end

  def dns_name_collision host, collision
    owner = collision.dns_name_owner
    content_tag(:fieldset) do
      legend("dns_name", collision.dns_name_entry) +
      arec(host.name, collision.dns_name_entry) +
      prec(collision.dns_name_entry, collision.dns_name_secondary_entry) +
      "Foreman owner: #{owner}"
    end
  end

  def macrec mac, address, style=""; rec mac, address, "Entry with this MAC", "macrec", style; end
  def iprec  address, mac, style=""; rec address, mac, "Entry with this IP", "iprec", style; end
  def rec key, value, header, klass, style, extra=nil
    key = value  = "------------------" if key == false or key.empty? or value == false or value.empty?
    content_tag(:div, :class => klass, :style=> style) do
      content_tag(:ul, :style => style) do
        content_tag(:li, header) +
        content_tag(:li, key) +
        content_tag(:li, value) +
        (extra ? content_tag(:li, extra) : "")
      end
    end
  end

  def dhcp_host_entry host, collision
    content_tag(:td, :colspan => 2) do
      content_tag(:fieldset) do
        content_tag(:legend, "Host's DHCP registration") +
        content_tag(:span,
          content_tag(:ul,
            content_tag(:li, host.mac)), :style => "float:left;" ) +
        content_tag(:span,
          content_tag(:ul,
            content_tag(:li, host.ip)),  :style => "float:right;")
      end
    end
  end

  def dhcp_collision_entries host, collision
    content_tag(:td, dhcp_mac_collision(host, collision)) +
    content_tag(:td, dhcp_ip_collision(host, collision))
  end

  def dhcp_mac_collision host, collision
    content_tag(:fieldset) do
      legend("dhcp_mac", collision.dhcp_mac_ip_entry) +
      macrec(host.mac, collision.dhcp_mac_ip_entry) +
      (collision.dhcp_mac_ip_collision_info ? content_tag(:ul, content_tag(:li, collision.dhcp_mac_ip_collision_info, :style => "color:BurlyWood ;")) : "")
    end
  end

  def dhcp_ip_collision host, collision
    content_tag(:fieldset) do
      legend("dhcp_ip", collision.dhcp_ip_mac_entry) +
      iprec(host.ip, collision.dhcp_ip_mac_entry) +
      (collision.dhcp_ip_mac_collision_info ? content_tag(:ul, content_tag(:li, collision.dhcp_ip_mac_collision_info, :style => "color:CornflowerBlue ;")) : "")
    end
  end

  def legend kind, bool
    legend  = "Existing #{kind.match(/_(.*)/)[1].upcase} record"
    content_tag(:legend, legend)
  end
end

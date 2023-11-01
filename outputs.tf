output "generated_from_template" {

    value = local_file.ansible_inventory.content
  
}
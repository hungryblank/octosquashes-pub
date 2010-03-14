function(doc) {
  var entries = {};
  for (idx in doc.entries) {
    var entry = doc.entries[idx];
    var entry_type = entry['id'].split(':').pop().split('/').shift().replace('Event', '');
    if ((doc.last_update - entry.published) < 1000 * 60 * 60 * 24) {
      if (entries[entry_type]) {
        entries[entry_type] += 1;
      } else {
        entries[entry_type] = 1;
      }
    }
  }
  var area = 0;
  for (entry_type in entries) {
    area += entries[entry_type];
  }
  var treemap_obj = {'id': doc['_id'], 'name': doc.title, 'description': doc.description, 'data':{'$area': area}, 'children': [], 'git_author': doc.author, 'git_resource_type': doc.resource_type}
  for (i in entries) {
    treemap_obj.children.push({'id': doc['_id'] + i, 'name': i, 'data': {'$area': entries[i]}, 'children': []});
  }
  var date = new Date(doc.last_update)
  var key = date.getFullYear().toString();
  emit(doc.last_update_string, treemap_obj);
}

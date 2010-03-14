var squasher = null

$(document).ready(function() {

  $('#treemap').height($(window).height() - $('#footer').outerHeight()).width($(window).width());

  $(document).bind('ajaxError', function() {
    alert('Error while fetching the data');
  });

  _.each(['about', 'credits'], function(menu_item) {
    $('a.' + menu_item).tooltip({tip: '#' + menu_item,
                                 position: 'top left',
                                 delay: 750});
  });
  squasher = new Squasher();

  $('#refresh a').click(function(){
    squasher.refresh();
    return false;
  })
});

function Squasher() {
  this.refresh();
}

Squasher.prototype.initTree = function() {
  return new TM.Squarified({
    rootId: 'treemap',
    selectPathOnHover: true,
    build_tooltip:
      $('#templates div').compile({"@id+": "node.id",
                             ".gh_element": "node.name",
                             ".gh_element@href+": "node.name",
                             "p": "description",
                             "li":{'gh_event<-gh_events': {'.':'gh_event'}}}),
    onCreateElement: function(content, node, isLeaf, head, body) {
      var jhead = $(head)
      if (isLeaf) {
        jhead.addClass(node.name);
      } else if (jhead.hasClass('head') && node.id != 'GitLast') {
        var git_entity = new GitEntity(node);
        $("#tooltips").append(this.build_tooltip({node: node, description: git_entity.description(), gh_events: git_entity.eventsString()}));
        jhead.tooltip({tip: '#tooltip_' + node.id,
                       events: {def: 'click, mouseout'},
                       position: 'bottom center',
                       offset: [10, 0],
                       effect: 'fade',
                       delay: 750}).dynamic()
      }
    }
  });
}

Squasher.prototype.refresh = function() {
  var tree = this.initTree();
  $('#refresh').fadeOut('slow', function() {
    $("#tooltips").children().remove();
    $.getJSON('/treemap.json?descending=true&limit=100', function(projects_view) {
      var tree_elements = _.map(projects_view.rows, function(row) { return row.value; });
      var total_area = _.reduce(tree_elements, 0, function(total, element) {
        return total + _.reduce(element.children, 0, function(sub_total, event_type){
          return sub_total + event_type['data']['$area'];
        });
      });
      tree.loadJSON({data:{$area: total_area},id:"GitLast",name:"Git Last",children:tree_elements});
      $('#refresh').fadeIn();
    })
  });
}

function GitEntity(node) {
  this.node = node
}

GitEntity.prototype.description = function() {
  if(this.node.git_resource_type == 'project') {
    return this.node.description || 'No description provided';
  }
  return 'Is a github user';
}

GitEntity.prototype.eventsString = function() {
  return _.map(this.node.children, function(gh_event) {
           return gh_event.data['$area'] + ' ' + gh_event.name;
         })
}

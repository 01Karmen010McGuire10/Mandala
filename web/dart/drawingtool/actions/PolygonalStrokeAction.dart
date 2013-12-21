part of DrawingToolLib;

class PolygonalStrokeAction extends BaseAction {
  static const String ACTION_NAME = "PolygonalStroke";
  static const int MIN_DISTANCE_BEFORE_CLOSING = 10;

  List<Geom.Point> _activePoints = null;
  Geom.Point       _potentialNextPoint = null;
  Geom.Point       _draggedPoint;

  /// Constructor
  PolygonalStrokeAction() : super(ACTION_NAME);

  void execute(CanvasRenderingContext2D ctx, width, height) {
    settings.execute(ctx);
    executeImp(ctx, ctx.stroke, width, height );
  }

  void executeImp( CanvasRenderingContext2D ctx, Function drawStyle, width, height ) {

    // If the active points are not empty - set points to draw to the union of points & activePoints
    List<Geom.Point> pointsToDraw = null;
    if( _activePoints != null ) {
      pointsToDraw = new List<Geom.Point>.from(points);
      pointsToDraw.add(BaseAction.LINE_BREAK);
      pointsToDraw.addAll( _activePoints );

      // If they're in the middle of drawing, add the current input position so they can see it as a preview
      if( _potentialNextPoint != null ) {
        pointsToDraw.add( _potentialNextPoint );
      }
    } else {
      pointsToDraw = points;
    }

    if (pointsToDraw.isEmpty || pointsToDraw.length < 3) return;

    for (var i = 0; i < pointsToDraw.length; i++) {
      // Null slot implies a new path should be started
      if (pointsToDraw[i] == BaseAction.LINE_BREAK) {

        // Close existing path
        if (i != 0) {
          drawStyle();
          ctx.closePath();
        }

        ctx.beginPath();
        ctx.moveTo(pointsToDraw[i + 1].x, pointsToDraw[i + 1].y);
        continue;
      }

      ctx.lineTo(pointsToDraw[i].x, pointsToDraw[i].y);
    }
    drawStyle();
    ctx.closePath();
  }

  void activeDraw(CanvasRenderingContext2D ctx, width, height, bool canEditPoints) {
    if( _activePoints != null ) {
      ctx..beginPath()
      ..setFillColorHsl(0, 80, 50)
      ..arc(_activePoints.first.x, _activePoints.first.y, 3, 0, PI*2, false)
      ..fill()
      ..closePath();
    } else if( canEditPoints) { // Drag points for dragging
      for(var i = 0; i < points.length; i++) {
        if( points[i] == BaseAction.LINE_BREAK ) continue;
        ctx.beginPath();
        ctx.arc(points[i].x, points[i].y, BaseAction.MIN_DRAG_DISTANCE, 0, PI * 2, false);
        ctx.stroke();
        ctx.closePath();
      }
    }
  }

  void inputDown(CanvasRenderingContext2D ctx, Geom.Point pos, bool canEditPoints) {

    if( canEditPoints ) {
      for(var i = 0; i < points.length; i++) {
        if( points[i] == BaseAction.LINE_BREAK ) continue;
        if( points[i].distanceTo( pos ) <= BaseAction.MIN_DRAG_DISTANCE ) {
          _draggedPoint = points[i];
          return;
        }
      }
    }

    if (_activePoints == null ) {
      _activePoints = new List<Geom.Point>();
      _activePoints.add(pos);
    }
  }

  void inputMove(CanvasRenderingContext2D ctx, Geom.Point pos, bool isDrag) {
    // Drag the control point instead
    if( _draggedPoint != null ) {
      _draggedPoint.copyFrom( pos );
      return;
    }

    _potentialNextPoint = pos;
  }

  void inputUp(CanvasRenderingContext2D ctx, Geom.Point pos, [bool forceClose = false] ) {
    // User was dragging - abort!
    if( _draggedPoint != null ) {
      _draggedPoint = null;
      return;
    }

    _activePoints.add(pos);

    if( _activePoints.length < 3 ) return;
    if( pos.distanceTo(_activePoints.first) < MIN_DISTANCE_BEFORE_CLOSING || forceClose ) {
      points.add(BaseAction.LINE_BREAK);
      points.addAll(_activePoints);

      _activePoints = null;
    }
  }
  
  /// If enter is pressed - close the path
  void keyPressed(CanvasRenderingContext2D ctx, KeyboardEvent e ){
    if( e.keyCode == KeyCode.ENTER ) {
      // Don't bother making a path if there are less than 3 points
      if( _activePoints == null || _activePoints.length < 3 ) {
        _activePoints = null;
        return; 
      }
      
      inputUp( ctx, _activePoints.last, true );
    }
  }

  void undo( CanvasRenderingContext2D ctx ) {
    int lastBreak = points.lastIndexOf( BaseAction.LINE_BREAK );
    if( lastBreak == -1 ) return;
    points.removeRange(lastBreak, points.length );
  }
  
}
